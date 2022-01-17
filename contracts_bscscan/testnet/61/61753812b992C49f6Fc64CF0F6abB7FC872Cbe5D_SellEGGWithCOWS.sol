// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {IERC721} from './IERC721.sol';
import {IERC721Enumerable} from './IERC721Enumerable.sol';
import {IERC721Metadata} from './IERC721Metadata.sol';
import {IUserCowsBoy} from './IUserCowsBoy.sol';
import './ReentrancyGuard.sol';

contract SellEGGWithCOWS is ReentrancyGuard {
  using SafeMath for uint256;
  // Todo : Update when deploy to production
  uint256 public constant DECIMAL_18 = 10**18;
  uint256 public constant PERCENTS_DIVIDER = 1000000000;
  address public operator;
  address public ContractNFTOwner;
  address public BUY_TOKEN;
  address public IDO_NFT_TOKEN;

  uint256 public tokenRate = 2000 * DECIMAL_18;
  mapping(address => uint256) public buyerAmount;
  uint256 public totalBuyIDO=0;

  struct NFTInfo {
        uint256 tokenID;
        uint256 amountBuy;
        uint256 claimAt;
        bool isEnable;
    }
  mapping(address => NFTInfo[]) public NFTSells;
  uint256 public totalSellNFT=0;

  bool public _paused = false;
 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event BuyNFT(address indexed user, uint256 indexed buyAmount);
  event ClaimNFT(address indexed user, uint256 indexed tokenid);

  modifier onlyAdmin() {
    require(msg.sender == operator, 'INVALID ADMIN');
    _;
  }


    constructor(address _buyToken,address _NFTToken) public {
        operator  = tx.origin;
        BUY_TOKEN = _buyToken;
        IDO_NFT_TOKEN = _NFTToken;
    }

    fallback() external {
    }

    receive() payable external {
        
    }


    function pause() public onlyAdmin {
      _paused=true;
    }

    function unpause() public onlyAdmin {
      _paused=false;
    }
    
    modifier ifPaused(){
      require(_paused,"");
      _;
    }

    modifier ifNotPaused(){
      require(!_paused,"");
      _;
    }  


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyAdmin {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(operator, newOwner);
        operator = newOwner;
    }
  

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken(address recipient, address token) public onlyAdmin {
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }

  /**
   * @dev 
   * @param recipients recipients of the transfer
   */
  function sendFTLNFTList(address[] calldata recipients,uint256[] calldata idTokens) public onlyAdmin {
    for (uint256 i = 0; i < recipients.length; i++) {
       IERC721(IDO_NFT_TOKEN).transferFrom(address(this),recipients[i], idTokens[i]);     
    }
  }

  
  /**
   * @dev Update rate
   */
  function updateRate(uint256 rate) public onlyAdmin {
    tokenRate = rate;
  }


  /**
   * @dev Update ContractOwner
   */
  function updateContractNFTOwner(address _ContractNFTOwner) public onlyAdmin {
    ContractNFTOwner = _ContractNFTOwner;
  }
    
    function getApproved(uint256 tokenId) external view returns (address){
        return IERC721(IDO_NFT_TOKEN).getApproved(tokenId);
    }

    function ownerOfNFT(uint256 tokenId) public view returns (address){
        return IERC721(IDO_NFT_TOKEN).ownerOf(tokenId);
    }

  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address payable recipient) public onlyAdmin {
    _safeTransferBNB(recipient, address(this).balance);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'BNB_TRANSFER_FAILED');
  }


  /**
   * @dev buy BuyEGG
   */

  function buyEGG() public ifNotPaused returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    require(tokenRate > 0, "Minium buy NFT");
    uint256 allowance = IERC20(BUY_TOKEN).allowance(msg.sender, address(this));
    require(allowance >= tokenRate, "Check the token allowance");
    uint256 balance = IERC20(BUY_TOKEN).balanceOf(msg.sender);
    require(balance >= tokenRate, "Sorry : not enough balance to buy ");
    require(IERC721(IDO_NFT_TOKEN).balanceOf(ContractNFTOwner) > 0, "Sorry : not enough NFT token balance to sale");

    IERC20(BUY_TOKEN).transferFrom(msg.sender, address(this), tokenRate);
    buyerAmount[msg.sender] += 1;
    emit BuyNFT(msg.sender , tokenRate);
    uint256 tokenId = IERC721Enumerable(IDO_NFT_TOKEN).tokenOfOwnerByIndex(ContractNFTOwner,0);
    if(ownerOfNFT(tokenId) != ContractNFTOwner)
    {
        revert("Please try again !");
    }
    IERC721(IDO_NFT_TOKEN).transferFrom(ContractNFTOwner,msg.sender, tokenId);
    NFTInfo memory nftSell;
    nftSell.tokenID=tokenId;
    nftSell.amountBuy=tokenRate;
    nftSell.claimAt= block.timestamp;
    NFTSells[msg.sender].push(nftSell);
    emit ClaimNFT(msg.sender,tokenId);
    return tokenId;
   }
}