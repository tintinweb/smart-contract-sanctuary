// SPDX-License-Identifier: MIT
import "./ERC1155.sol";

pragma solidity >=0.6.0 <0.8.0;

  /**
   * @dev Contract module which provides a basic access control mechanism, where
   * there is an account (an owner) that can be granted exclusive access to
   * specific functions.
   *
   * By default, the owner account will be the one that deploys the contract. This
   * can later be changed with {transferOwnership}.
   *
   * This module is used through inheritance. It will make available the modifier
   * `onlyOwner`, which can be applied to your functions to restrict their use to
   * the owner.
   */
  abstract contract Ownable is Context {
      address private _owner;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

      /**
       * @dev Initializes the contract setting the deployer as the initial owner.
       */
      constructor () internal {
          address msgSender = _msgSender();
          _owner = msgSender;
          emit OwnershipTransferred(address(0), msgSender);
      }

      /**
       * @dev Returns the address of the current owner.
       */
      function owner() public view returns (address) {
          return _owner;
      }

      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
          require(_owner == _msgSender(), "Ownable: caller is not the owner");
          _;
      }

      /**
       * @dev Leaves the contract without owner. It will not be possible to call
       * `onlyOwner` functions anymore. Can only be called by the current owner.
       *
       * NOTE: Renouncing ownership will leave the contract without an owner,
       * thereby removing any functionality that is only available to the owner.
       */
      function renounceOwnership() public virtual onlyOwner {
          emit OwnershipTransferred(_owner, address(0));
          _owner = address(0);
      }

      /**
       * @dev Transfers ownership of the contract to a new account (`newOwner`).
       * Can only be called by the current owner.
       */
      function transferOwnership(address newOwner) public virtual onlyOwner {
          require(newOwner != address(0), "Ownable: new owner is the zero address");
          emit OwnershipTransferred(_owner, newOwner);
          _owner = newOwner;
      }
  }

  interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    /**
     * TODO: Add comment
     */
    function burn(uint256 burnQuantity) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma experimental ABIEncoderV2;

contract VNSC is ERC1155, Ownable {

    struct UserInfo {
        uint256 time;
        address user;
    }

  // Hashes of meme pictures on IPFS
  string[] public hashes;
  // Mapping for enforcing unique hashes
  mapping(string => bool) _hashExists;

  // Mapping from NFT token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from hash to NFT token ID
  mapping (string => address) private _hashToken;

    string public coinMost = "https://yaoufei-1302093849.cos.ap-nanjing.myqcloud.com/2005abe65ac0939ecad1.jpg";   //100u,1800份
    string public coinSec = "https://yaoufei-1302093849.cos.ap-nanjing.myqcloud.com/4ea8f1d006f6cfa896e7.jpg"; //500u,800份
    string public coinThird = "https://yaoufei-1302093849.cos.ap-nanjing.myqcloud.com/bd78acc241e488bad1f5.jpg"; //1000u,400份

    IERC20 private _token = IERC20(0x2d609440e9156CB0C579f02dC248e849387fDb4f);
    address private _etwallet = 0x574934F1f40A7f12dAd4E132FeF2a42485804920;
    address private _twWallet = 0xAE38AC0073F391dc8732E8536d6D5Df12E40e847;

    mapping (address => address) private _firstInvitors;  //一级邀请
    mapping (address => address) private _secInvitors;    //二级邀请
    mapping (address => uint256) private _reword;         //奖励
    mapping (uint256 => uint256) private _coinTypeMap;       //nft类型
    mapping (address => UserInfo[]) public _userFirst;  //用户的直推列表
    mapping (address => UserInfo[]) public _userSec;    //用户的间推列表
    
    uint256 private firstCoin = 1800;
    uint256 private secCoin = 800;
    uint256 private thirdCoin = 400;
    uint256 private firstCount = 0;
    uint256 private secCount = 0;
    uint256 private thirdCount = 0;
    uint256 public saleStartTimestamp = 1620144000;
    uint256 public revealTimestamp = saleStartTimestamp + (86400 * 7);
    uint256 public totalSupply = 0;

  constructor() public ERC1155("https://game.example/api/item/{id}.json") {
  }

  function buyCoin(uint256 numberOfNfts, uint256 coinType, address invitor) public returns(bool) {
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        string memory uri = coinMost;
        if (coinType == 3) {
            require(thirdCount<thirdCoin, "coin sold out");
            require(thirdCount.add(numberOfNfts)<thirdCoin, "coin not enough to sell");
            thirdCount = thirdCount.add(1);
            uri = coinThird;
        }else if (coinType == 2) {
            require(secCount<secCoin, "coin sold out");
            require(secCount.add(numberOfNfts)<secCoin, "coin not enough to sell");
            secCount = secCount.add(1);
            uri = coinSec;
        }else {
            require(firstCount<firstCoin, "coin sold out");
            require(firstCount.add(numberOfNfts)<firstCoin, "coin not enough to sell");
            firstCount = firstCount.add(1);
        }
       
        uint256 fee = getNFTPrice(coinType).mul(numberOfNfts);
        require(fee<100000000000000000000000, "over number");
        _token.transferFrom(_msgSender(), address(this), fee);
        //require(getNFTPrice(coinType).mul(numberOfNfts) == msg.value, "BNB value sent is not correct");

        //分润
        if (invitor != address(0)) {
            if (_firstInvitors[msg.sender] == address(0) && invitor!=msg.sender) {
                _firstInvitors[msg.sender] = invitor;
                _userFirst[invitor].push(UserInfo({
                    time: block.timestamp,
                    user: msg.sender
                }));
            }

          _reword[_firstInvitors[msg.sender]] = _reword[_firstInvitors[msg.sender]].add(fee.mul(2).div(100));
          if (_firstInvitors[invitor] != address(0) && invitor!=msg.sender) {  //二级邀请者
            if (_firstInvitors[msg.sender] == address(0)) {
                _secInvitors[msg.sender] = _firstInvitors[invitor];
                _userSec[_firstInvitors[invitor]].push(UserInfo(block.timestamp, msg.sender));
            }
            _reword[_firstInvitors[invitor]] = _reword[_firstInvitors[invitor]].add(fee.div(100));
          }
        }

        for (uint i = 0; i < numberOfNfts; i++) {
            //uint mintIndex = totalSupply + 1;
            _mint(msg.sender, 1, 1, uri, "");
            totalSupply = totalSupply.add(1);
        }

        return true;
    }

    function claim() public returns(bool) {
        require(_reword[msg.sender]>0, "balance empty");

        // address payable addr = address(uint160(msg.sender));
        uint256 amount = _reword[msg.sender];
        //addr.transfer(amount);
        _token.transferFrom(address(this), _msgSender(), amount);
        _reword[msg.sender] = 0;
        return true;
    }

//   function mint(string memory _hash, string memory _uri) public {
//     require(!_hashExists[_hash], "Token is already minted");
//     require(bytes(_uri).length > 0, "uri should be set");
//     hashes.push(_hash);
//     uint _id = hashes.length - 1;
//     _mint(msg.sender, _id, 1, _uri, "");
//     _hashExists[_hash] = true;
//   }

    function userFirstList(address user) public view returns(UserInfo[] memory) {
        return _userFirst[user];
    }

    function userSecondList(address user) public view returns(UserInfo[] memory) {
        return _userSec[user];
    }

    function userInvitor(address user) public view returns(address) {
        return _firstInvitors[user];
    }

    function userReword(address user) public view returns(uint256) {
        return _reword[user];
    }

    function getNFTPrice(uint256 coinType) public pure returns (uint256) {
        //require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        //uint256 perPrice = getLatestPrice();
        if (coinType == 3) {
            //return 800000000000000000;     //0.8bnb
            return 1000000000000000000000;
          //return 1000.div(perPrice).mul(10000000000000000000);
        }else if (coinType == 2) {
            //return 300000000000000000;  //0.3
            return 500000000000000000000;
        }else {
            //return 100000000000000000; //0.1
            return 100000000000000000000;
        //   return 100.div(perPrice).mul(10000000000000000000); // 1 - 3000 0.08 BNB
        }
    }

//   function getMemesCount() public view returns(uint256 count) {
//     return hashes.length;
//   }

  function uri(uint256 _tokenId) public view override returns(string memory _uri) {
    return _tokenURI(_tokenId);
  }

  function setTokenUri(uint256 _tokenId, string memory _uri) public onlyOwner {
    _setTokenURI(_tokenId, _uri);
  }

//   function safeTransferFromWithProvision(
//     address payable from,
//     address to,
//     uint256 id,
//     uint256 amount,
//     uint256 price
//   )
//     public payable returns(bool approved)
//   {
//     setApprovalForAll(to,true);
//     safeTransferFrom(from, to, id, amount, "0x0");
//     return isApprovedForAll(from, to);
//     //from.transfer(price);
//   }

}