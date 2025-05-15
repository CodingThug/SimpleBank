// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank public simpleBank;
    address public constant USER = address(0x1234);
    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant CREATE_USER_FEE = 0.0005 ether;

    function setUp() public {
        simpleBank = new SimpleBank();
        vm.deal(USER, 1 ether);
    }

    // Test successful user creation
    function test_CreateUser_Success() public {
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Alice", 25, "Engineer", true, SimpleBank.GENDER.FEMALE);

        // Check user creation via getHolderInfo
        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender) =
            simpleBank.getHolderInfo("Alice");
        assertEq(userid, 1);
        assertEq(age, 25);
        assertEq(occupation, "Engineer");
        assertTrue(isMarried);
        assertEq(gender, "female");

        // Check userId increment
        assertEq(simpleBank.userId(), 2);
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

        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender) =
            simpleBank.getHolderInfo("Alice");
        assertEq(userid, 1);
        assertEq(age, 25);
        assertEq(occupation, "Engineer");
        assertTrue(isMarried);
        assertEq(gender, "female");
    }

    // Test getHolderInfo for non-existent user
    function test_GetHolderInfo_NonExistent() public view {
        (uint256 userid, uint256 age, string memory occupation, bool isMarried, string memory gender) =
            simpleBank.getHolderInfo("Bob");
        assertEq(userid, 0);
        assertEq(age, 0);
        assertEq(occupation, "");
        assertFalse(isMarried);
        assertEq(gender, "nonselected");
    }

    // Test different gender options
    function test_CreateUser_DifferentGenders() public {
        // Test MALE
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(USER, "Bob", 30, "Doctor", false, SimpleBank.GENDER.MALE);
        (,,, bool isMarried, string memory gender) = simpleBank.getHolderInfo("Bob");
        assertFalse(isMarried);
        assertEq(gender, "male");

        // Test NONSELECTED
        vm.prank(USER);
        simpleBank.createUser{value: CREATE_USER_FEE}(
            address(0x5678), "Charlie", 40, "Teacher", true, SimpleBank.GENDER.NONSELECTED
        );
        (,,,, gender) = simpleBank.getHolderInfo("Charlie");
        assertEq(gender, "nonselected");
    }
}
