// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank public simpleBank;
    address public constant USER = address(0x1234);
    address public constant USER2 = address(0x5678);
    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant CREATE_USER_FEE = 0.0005 ether;
    address public owner;

    function setUp() public {
        // Deploy contract and set owner as the deployer
        owner = address(this);
        simpleBank = new SimpleBank();
        vm.deal(USER, 1 ether);
        vm.deal(USER2, 1 ether);
    }

    // Test getCreateFeePrice returns correct fee
    function test_GetCreateFeePrice() public view {
        uint256 fee = simpleBank.getCreateFeePrice();
        assertEq(fee, CREATE_USER_FEE);
    }

    // Test successful user creation
    function test_CreateUser_Success() public {
        vm.prank(USER);
        // Expect UserCreated event to be emitted
        vm.expectEmit(true, false, false, true);
        emit SimpleBank.UserCreated(USER, "Alice");
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        // Verify user data via getHolderInfo
        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender, uint256 balance) =
            simpleBank.getHolderInfo("Alice");
        assertEq(userid, 1);
        assertEq(age, 25);
        assertEq(occupation, "Engineer");
        assertTrue(isMarried);
        assertEq(gender, "female");
        assertEq(balance, CREATE_USER_FEE);
    }

    // Test createUser with incorrect fee
    function test_CreateUser_Fail_IncorrectFee() public {
        vm.prank(USER);
        vm.expectRevert("you gotta come correct my g.");
        simpleBank.createUser{value: 0.0001 ether}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);
    }

    // Test createUser with zero address
    function test_CreateUser_Fail_ZeroAddress() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(SimpleBank.InvalidAddress.selector, ZERO_ADDRESS, ZERO_ADDRESS));
        simpleBank.createUser{value: CREATE_USER_FEE}(
            ZERO_ADDRESS, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE
        );
    }

    // Test getHolderInfo for existing user
    function test_GetHolderInfo_Success() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender, uint256 balance) =
            simpleBank.getHolderInfo("Alice");
        assertEq(userid, 1);
        assertEq(age, 25);
        assertEq(occupation, "Engineer");
        assertTrue(isMarried);
        assertEq(gender, "female");
        assertEq(balance, CREATE_USER_FEE);
    }

    // Test getHolderInfo for non-existent user
    function test_GetHolderInfo_NonExistent() public view {
        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender, uint256 balance) =
            simpleBank.getHolderInfo("Bob");
        assertEq(userid, 0);
        assertEq(age, 0);
        assertEq(occupation, "");
        assertFalse(isMarried);
        assertEq(gender, "nonselected");
        assertEq(balance, 0);
    }

    // Test different gender options
    function test_CreateUser_DifferentGenders() public {
        // Test MALE
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Bob", 30, "Doctor", false, SimpleBank.GENDER.MALE);
        (,,, bool isMarried, string memory gender,) = simpleBank.getHolderInfo("Bob");
        assertFalse(isMarried);
        assertEq(gender, "male");

        // Test NONSELECTED
        vm.prank(USER2);
        simpleBank.createUser{value: CREATE_USER_FEE}(
            USER2, "Charlie", 40, "Teacher", true, SimpleBank.GENDER.NONSELECTED
        );
        (,,, isMarried, gender,) = simpleBank.getHolderInfo("Charlie");
        assertTrue(isMarried);
        assertEq(gender, "nonselected");
    }

    // Test successful deposit
    function test_MakeDeposit_Success() public {
        // Register a user
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        // Deposit 0.1 ether
        vm.prank(USER);
        vm.expectEmit(true, false, false, true);
        emit SimpleBank.Deposited(USER, 0.1 ether);
        simpleBank.makeDeposit{value: 0.1 ether}();

        // Verify user's balance
        (,,,,, uint256 balance) = simpleBank.getHolderInfo("Alice");
        assertEq(balance, CREATE_USER_FEE + 0.1 ether);
    }

    // Test deposit with zero amount
    function test_MakeDeposit_Fail_ZeroAmount() public {
        vm.prank(USER);
        vm.expectRevert("Deposit amount must be greater than 0");
        simpleBank.makeDeposit{value: 0}();
    }

    // Test successful withdrawal
    function test_Withdraw_Success() public {
        // Register a user and deposit
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);
        vm.prank(USER);
        simpleBank.makeDeposit{value: 0.1 ether}();

        // Withdraw 0.05 ether
        uint256 initialBalance = USER.balance;
        vm.prank(USER);
        vm.expectEmit(true, false, false, true);
        emit SimpleBank.FundsWithdrawn(USER, 0.05 ether);
        simpleBank.withdraw(0.05 ether);

        // Verify user's balance and received funds
        (,,,,, uint256 balance) = simpleBank.getHolderInfo("Alice");
        assertEq(balance, CREATE_USER_FEE + 0.05 ether);
        assertEq(USER.balance, initialBalance + 0.05 ether);
    }

    // Test withdrawal with insufficient balance
    function test_Withdraw_Fail_InsufficientBalance() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        vm.prank(USER);
        vm.expectRevert("Insufficient balance");
        simpleBank.withdraw(CREATE_USER_FEE + 1);
    }

    // Test withdrawal with zero amount
    function test_Withdraw_Fail_ZeroAmount() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        vm.prank(USER);
        vm.expectRevert("Withdrawal amount must be greater than 0");
        simpleBank.withdraw(0);
    }

    // Test owner withdrawing contract funds
    function test_WithdrawContractFunds_Success() public {
        // Register a user to add funds to contract
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        // Owner withdraws 0.0005 ether to USER2
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit SimpleBank.FundsWithdrawn(USER2, CREATE_USER_FEE);
        simpleBank.withdrawContractFunds(payable(USER2), CREATE_USER_FEE);

        // Verify contract balance and recipient balance
        assertEq(address(simpleBank).balance, 0);
        assertEq(USER2.balance, 1 ether + CREATE_USER_FEE);
    }

    // Test non-owner attempting to withdraw contract funds
    function test_WithdrawContractFunds_Fail_NonOwner() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        vm.prank(USER);
        vm.expectRevert("Only the owner of this contract can call this function.");
        simpleBank.withdrawContractFunds(payable(USER2), CREATE_USER_FEE);
    }

    // Test owner withdrawing with zero amount
    function test_WithdrawContractFunds_Fail_ZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("Withdrawal amount must be greater than 0");
        simpleBank.withdrawContractFunds(payable(USER2), 0);
    }

    // Test owner withdrawing with insufficient contract balance
    function test_WithdrawContractFunds_Fail_InsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert("Insufficient contract balance");
        simpleBank.withdrawContractFunds(payable(USER2), CREATE_USER_FEE);
    }

    // Test owner withdrawing to zero address
    function test_WithdrawContractFunds_Fail_InvalidRecipient() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        vm.prank(owner);
        vm.expectRevert("Invalid recipient address");
        simpleBank.withdrawContractFunds(payable(ZERO_ADDRESS), CREATE_USER_FEE);
    }
}
