// SPDX-License-Identifier: GPL-2.0-or-later



import "../interface/trademint/ISummaSwapV3Manager.sol";
import "../libraries/Owned.sol";

contract SummaManagerSnap is Owned{


    ISummaSwapV3Manager public iSummaSwapV3Manager;

    function setISummaSwapV3Manager(ISummaSwapV3Manager _ISummaSwapV3Manager)
        public
        onlyOwner
    {
        iSummaSwapV3Manager = _ISummaSwapV3Manager;
    }
    

    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return iSummaSwapV3Manager.balanceOf(owner);
    }

    

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view  returns (uint256) {
        return iSummaSwapV3Manager.tokenOfOwnerByIndex(
                owner,
                index
            );
    }

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        if(tokenId <113){
            return iSummaSwapV3Manager.positions(tokenId);
        }else{
            return (
            0,
            address(0),
            address(0),
            address(0),
            3000,
            0,
            0,
            0,
            0,
            0,
            0,
            0);
        }
    }


     /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view  returns (address) {
        return iSummaSwapV3Manager.ownerOf(tokenId);
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ISummaSwapV3Manager{
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
        
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view  returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view   returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}