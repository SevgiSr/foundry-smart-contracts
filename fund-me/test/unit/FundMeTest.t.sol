// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

// setUp() always runs first.
// later we'll learn to import deploy scripts from scripts/ folder to make deployment env same as the testing env
// but right now we gonna make setUp() deploy our contract

import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // deploy FUndMe for local unit testing
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // give user money
    }

    // best practise
    modifier funded() {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // but user needs money, which is set with .deal()
        _;
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        // local network rn (anvil) this wont work without mocks cuz priceFeed doesnt exist on anvil
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
        // make this work without mocks by FORKING sepolia testnet (not actually testing on testnet)
        // add rpc url from alchemy to .env
        // load env vars from .env into the current shell session with > source .env
        // > forge test --mt testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
        // now it passes!

        // you can fork mainnet either
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArraOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    // we funded so theres money first
    function testOnlyOwnerCanWithdraw() public funded {
        // user is not the owner, expect revert
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // TESTING PATTERN
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner()); // only the owner can withdraw
        fundMe.withdraw();
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank + vm.deal = hoax()
            hoax(address(i), SEND_VALUE);
            //fund
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(address(fundMe).balance == 0);
        // how these are equal, shouldn't the owner have spent gas when calling withdraw?
        // cuz anvil defaults gas price to 0
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
