// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleBank {
    address owner;
    uint256 internal constant CREATE_USER_FEE = 0.0005 ether;
    uint256 internal userId = 1;

    struct Banker {
        uint256 userid;
        string name;
        address holder;
        uint256 age;
        string occupation;
        bool isMarried;
        GENDER selection;
    }

    mapping(address => Banker) internal holderByWalletAddress;
    mapping(string => Banker) internal holderByName;
    mapping(address => uint256) internal balances;
    mapping(address => uint256) internal depositTimestamp;

    enum GENDER {
        NONSELECTED,
        MALE,
        FEMALE
    }

    error InvalidAddress(address newUser, address oldUser);

    event UserCreated(address createdUser, string name);
    event UserRemoved(address banker, string name);
    event FundsWithdrawn(address to, uint256 amount);
    event Receive(address sender, uint256 value);
    event Fallback(address sender, string message);
    event Deposited(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract can call this function.");
        _;
    }

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Returns the fixed fee for creating a user
    function getCreateFeePrice() public pure returns (uint256) {
        return CREATE_USER_FEE;
    }

    // Creates a new user, storing their info and depositing the fee to the contract
    function createUser(
        address currentHolderWalletAddress,
        string memory holderName,
        uint256 age,
        string memory occupation,
        bool isMarried,
        GENDER _gender
    ) public payable {
        require(msg.value == CREATE_USER_FEE, "you gotta come correct my g.");

        if (currentHolderWalletAddress == address(0)) revert InvalidAddress(currentHolderWalletAddress, address(0));

        Banker memory newHolder = Banker({
            userid: userId,
            name: holderName,
            holder: currentHolderWalletAddress,
            age: age,
            occupation: occupation,
            isMarried: isMarried,
            selection: _gender
        });

        holderByWalletAddress[currentHolderWalletAddress] = newHolder;
        holderByName[holderName] = newHolder;
        balances[currentHolderWalletAddress] = msg.value;
        depositTimestamp[currentHolderWalletAddress] = block.timestamp;

        // Emit UserCreated event to log the new user
        emit UserCreated(currentHolderWalletAddress, holderName);

        userId++;
    }

    // Retrieves user information, including their balance, by name
    function getHolderInfo(string memory name)
        public
        view
        returns (
            uint256 currentUserId,
            uint256 age,
            string memory occupation,
            bool isMarried,
            string memory gender,
            uint256 balance
        )
    {
        Banker memory holder = holderByName[name];
        string memory genderStr =
            holder.selection == GENDER.MALE ? "male" : holder.selection == GENDER.FEMALE ? "female" : "nonselected";
        return (holder.userid, holder.age, holder.occupation, holder.isMarried, genderStr, balances[holder.holder]);
    }

    // Returns the caller's balance stored in the contract
    function justMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Allows users to deposit funds, adding to their balance in the contract
    function makeDeposit() public payable {
        // Ensure the deposit amount is greater than 0
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Add the deposited amount to the user's balance
        balances[msg.sender] += msg.value;

        // Emit event to log the deposit
        emit Deposited(msg.sender, msg.value);
    }

    // Allows users to withdraw funds from their own balance
    function withdraw(uint256 amount) public {
        // Ensure the requested amount is greater than 0
        require(amount > 0, "Withdrawal amount must be greater than 0");
        // Ensure the user has sufficient balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Update the user's balance
        balances[msg.sender] -= amount;

        // Transfer the amount to the user
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        // Emit event to log the withdrawal
        emit FundsWithdrawn(msg.sender, amount);
    }

    // Allows only the owner to withdraw the contract's balance to a specified address
    function withdrawContractFunds(address payable recipient, uint256 amount) public onlyOwner {
        // Ensure the recipient address is valid
        require(recipient != address(0), "Invalid recipient address");
        // Ensure the requested amount is greater than 0
        require(amount > 0, "Withdrawal amount must be greater than 0");
        // Ensure the contract has sufficient balance
        require(address(this).balance >= amount, "Insufficient contract balance");

        // Transfer the amount to the recipient
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Contract withdrawal failed");

        // Emit event to log the withdrawal
        emit FundsWithdrawn(recipient, amount);
    }

    // Allows only the owner to remove a banker and their data
    function removeBanker(address banker) public onlyOwner {
        // Ensure the banker exists
        require(holderByWalletAddress[banker].holder != address(0), "Banker does not exist");

        // Delete banker from mappings
        string memory name = holderByWalletAddress[banker].name;
        delete holderByWalletAddress[banker];
        delete holderByName[name];

        // Reset balance and deposit timestamp
        delete balances[banker];
        delete depositTimestamp[banker];

        // Emit event to log the removal
        emit UserRemoved(banker, name);
    }

    // Handles direct ETH transfers to the contract
    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    // Handles non-existent function calls
    fallback() external payable {
        emit Fallback(msg.sender, string(msg.data));
    }
}
