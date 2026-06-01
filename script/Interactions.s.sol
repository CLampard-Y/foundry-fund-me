// SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

error Interactions__InvalidFundMeAddress();
error Interactions__FundMeAddressHasNoCode(address fundMe);
error Interactions__InsufficientBalance(address account, uint256 balance, uint256 required);

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

    function fundFundMe(address mostRecentlyDeployed) public {
        _validateFundMeAddress(mostRecentlyDeployed);

        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        // Search for the most recent deployment of FundMe in now chain
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script, InteractionValidator {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        _validateFundMeAddress(mostRecentlyDeployed);

        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed);
    }
}
