// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleBank {
    address owner;
    uint256 public constant CREATE_USER_FEE = 0.0005 ether;
    uint256 public userId = 1;

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
    event FundsWithdrawn(address to, uint256 amount);
    event Receive(address sender, uint256 value);
    event Fallback(address sender, string message);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract can call this function.");
        _;
    }

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

        userId++;
    }

    function getHolderInfo(string memory name)
        public
        view
        returns (uint256 currentUserId, uint256 age, string memory occupation, bool isMarried, string memory gender)
    {
        Banker memory holder = holderByName[name];
        string memory genderStr =
            holder.selection == GENDER.MALE ? "male" : holder.selection == GENDER.FEMALE ? "female" : "nonselected";
        return (holder.userid, holder.age, holder.occupation, holder.isMarried, genderStr);
    }
}
