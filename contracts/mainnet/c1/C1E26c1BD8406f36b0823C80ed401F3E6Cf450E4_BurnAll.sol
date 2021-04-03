/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.5.0;


interface IERC1155 {
    function burn(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) external;
}

/**
 * @title BCCG
 * BCCG - The Official Bondly Collectible Card Game
 */
contract BurnAll {
    function batchBurn(
        address _contract,
        address[] memory _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public {
        IERC1155 funnyContract = IERC1155(_contract);
        for (uint16 i = 0; i < _from.length; i++) {
            funnyContract.burn(_from[i], _ids[i], _amounts[i]);
        }
    }
}