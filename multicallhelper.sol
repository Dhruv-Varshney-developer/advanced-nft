// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MulticallTestHelpers {
    function generateTransferFromData(
        address from,
        address to,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IERC721.transferFrom.selector,
                from,
                to,
                tokenId
            );
    }

    function generateMulticallData(bytes[] memory calls)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("multicall(bytes[])")),
                calls
            );
    }
}
