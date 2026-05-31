// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    uint256 private constant UNSUPPORTED_CHAINID = 100;

    function testRevertsOnUnsupportedChainId() public {
        uint256 unsupportedChainId = UNSUPPORTED_CHAINID;

        vm.chainId(unsupportedChainId);
        vm.expectRevert(
            abi.encodeWithSelector(HelperConfig.HelperConfig__UnsupportedChainId.selector, unsupportedChainId)
        );

        new HelperConfig();
    }
}
