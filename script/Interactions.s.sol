// SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

error Interactions__InvalidFundMeAddress();
error Interactions__FundMeAddressHasNoCode(address fundMe);
//error Interactions__InsufficientBalance(address account, uint256 balance, uint256 required);

abstract contract InteractionValidator {
    function _validateFundMeAddress(address fundMe) internal view {
        if (fundMe == address(0)) {
            revert Interactions__InvalidFundMeAddress();
        }

        if (fundMe.code.length == 0) {
            revert Interactions__FundMeAddressHasNoCode(fundMe);
        }
    }
}

// Inherit Script from the Script contract
contract FundFundMe is Script, InteractionValidator {
    uint256 internal constant SEND_VALUE = 0.1 ether;

    function fundFundMe(address fundMeAddress) public {
        _validateFundMeAddress(fundMeAddress);

        // Simple version check
        // Lack: msg.sender not always equal to real EOA
        // forge script script/Interactions.s.sol:FundFundMe --private-key $PRIVATE_KEY --broadcast
        /*
        if (msg.sender.balance < SEND_VALUE) {
            revert Interactions__InsufficientBalance(msg.sender, msg.sender.balance, SEND_VALUE);

        vm.startBroadcast();
        FundMe(payable(fundMeAddress)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
        */

        // Advanced version check
        /*
        uint256 deployerKey = vm.envUint("ANVIL_PRIVATE_KEY");
        address broadcaster = vm.addr(deployerKey);

        if (broadcaster.balance < SEND_VALUE) {
            revert Interactions__InsufficientBalance(broadcaster, broadcaster.balance, SEND_VALUE);
        }

        vm.startBroadcast(deployerKey);
        FundMe(payable(fundMeAddress)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
        */

        // For now using simple version
        // Keep broadcasting CLI-driven to support different networks without hardcoding private keys
        vm.startBroadcast();
        FundMe(payable(fundMeAddress)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
    }

    // Lack: most recent deployment not always the one that you want to interact with
    function run() external {
        // Search for the most recent deployment of FundMe in now chain
        address fundMeAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(fundMeAddress);
    }
}

contract WithdrawFundMe is Script, InteractionValidator {
    function withdrawFundMe(address fundMeAddress) public {
        _validateFundMeAddress(fundMeAddress);

        vm.startBroadcast();
        FundMe(payable(fundMeAddress)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address fundMeAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(fundMeAddress);
    }
}
