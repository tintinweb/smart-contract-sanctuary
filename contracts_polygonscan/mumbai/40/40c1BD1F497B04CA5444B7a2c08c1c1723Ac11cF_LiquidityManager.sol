// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11 < 0.9.0;

import './Owned.sol';
import './IERC20.sol';
import './IWETH9.sol';
import './TransferHelper.sol';
import './IERC721Receiver.sol';
import './INonfungiblePositionManager.sol';

contract LiquidityManager is IERC721Receiver {
    /** USEFUL ADDRESSES
    
    WMATIC (Mumbai): 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
    LMAO (Mumbai): 0x529ed2838531cf3f5f4ceadB7391434f4D7295A9
    NonfungiblePositionManager (Mumbai): 0xc36442b4a4522e871399cd717abdd847ab11fe88
    
    WMATIC (Mainnet): 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    
    WETH (kovan): 0xF3A6679B266899042276804930B3bFBaf807F15b
    **/

    address private aWMATIC_Mumbai = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private aLMAO_Mumbai = 0x529ed2838531cf3f5f4ceadB7391434f4D7295A9;
    address private aNonfungiblePositionManager_Mumbai = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    

    address private immutable TOKEN = aLMAO_Mumbai;
    address private immutable WETH9 = aWMATIC_Mumbai;
    address private immutable aNonfungiblePositionManager = aNonfungiblePositionManager_Mumbai;
    
    address private immutable _thisAddress;
    address private immutable _owner;

    uint256 private _tokensPerWETH = 100 ether / 1 ether;

    uint8 private immutable _developerFeeBasisPoints = 200; // 1 basis point = 1/100 percent = 1/10000
    address private _developerAddress = 0x7C87D8bd4B8d24dBF0f90E0795F6FD34C9bf643c;

    INonfungiblePositionManager private immutable _nonfungiblePositionManager;

    mapping (uint256 => address) private _poolHolders;

    event ERC721Received(address from, uint256 tokenId);

    modifier onlyOwner {
        require(
            msg.sender == _owner,
            "Only owner can call this function."
        );
        _;
    }

    constructor () {
        _owner = msg.sender;
        _thisAddress = address(this);
        _nonfungiblePositionManager = INonfungiblePositionManager(aNonfungiblePositionManager);
    }

    function setDevAddress(address newDevAddress) public onlyOwner {
        _developerAddress = newDevAddress;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit ERC721Received(from, tokenId);
        return this.onERC721Received.selector;
    }

    function removeUnusedTokensAndWETH() public onlyOwner {
        IWETH9(WETH9).transfer(_owner, IWETH9(WETH9).balanceOf(_thisAddress));
        IERC20(TOKEN).transfer(_owner, IERC20(TOKEN).balanceOf(_thisAddress));
    }

    function getPoolHolder(uint256 tokenId) public view returns (address) {
        return _poolHolders[tokenId];
    }

    function acceptETHAndCreatePool() public payable {

        // Wrap ETH sent by user to WETH 
        IWETH9(WETH9).deposit{value: msg.value}();

        // Pay developer fee
        uint256 developerFee = msg.value * _developerFeeBasisPoints / 10000;        
        IWETH9(WETH9).transfer(_developerAddress, developerFee);

        uint256 amountWeth9 = msg.value - developerFee;
        uint256 amountToken = _tokensPerWETH * amountWeth9;
        
        // Approve WETH 
        TransferHelper.safeApprove(WETH9, address(_nonfungiblePositionManager), amountWeth9);
        TransferHelper.safeApprove(TOKEN, address(_nonfungiblePositionManager), amountToken);
       

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: TOKEN,
                token1: WETH9,
                fee: 3000,
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: amountToken,
                amount1Desired: amountWeth9,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        

        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        

        // Note that the pool defined by TOKEN/WETH and fee tier 0.3% must already be created and initialized in order to mint.
        (tokenId, liquidity, amount0, amount1) = _nonfungiblePositionManager.mint(params);
        
        // Add sender to _poolHolders
        // _poolHolders.push( PoolHolder(tokenId, msg.sender) );
        _poolHolders[tokenId] = msg.sender;

        // Send pool token to its holder
        _nonfungiblePositionManager.transferFrom(_thisAddress, _poolHolders[tokenId], tokenId);
        
        // Remove allowance and refund in both assets.
        if (amount0 < amountToken) {
            TransferHelper.safeApprove(TOKEN, address(_nonfungiblePositionManager), 0);
            uint256 refund0 = amountToken - amount0;
            TransferHelper.safeTransfer(TOKEN, msg.sender, refund0);
        }

        if (amount1 < amountWeth9) {
            TransferHelper.safeApprove(WETH9, address(_nonfungiblePositionManager), 0);
            uint256 refund1 = amountWeth9 - amount1;
            TransferHelper.safeTransfer(WETH9, msg.sender, refund1);
        }
    }
    
    

}