/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// File: Demos/ZecreyFaucet.sol


pragma solidity >=0.7.0 <0.9.0;

interface ERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

contract ZecreyFaucet {

    ERC20 private faucetToken;
    uint256[] assetIDs;

    mapping(uint256 => address) public tokenMap; // assetID -> token Address

    address private owner;
    uint256 public threshold;
    uint256 public amount; // each time to claim $amount token

    constructor() {
        owner = msg.sender;
        threshold = 1 * 10**18;
        amount = 10 * 10 **18; // decimals: 18
    }

    /** global params setting
        threshold: if less than this number -> claimable, otherwise -> unclaimable
        amount: when claimable, how many tokens could be claimed
    */
    function setThreshold(uint256 _amount) external onlyOwner {
        threshold = _amount;
    }
    function setAmount(uint256 _amount) external onlyOwner {
        amount = _amount;
    }
    /*******************************/

    function setFaucetTokenMap(uint256 _assetID, address _token) external {
        tokenMap[_assetID] = _token;
        assetIDs.push(_assetID);
    }

    // Claim one faucet token
    function claim(uint256 _assetID) external {
        ERC20 _faucetToken = ERC20(tokenMap[_assetID]);
        require(_faucetToken.balanceOf(msg.sender) < threshold, "You have enough testnet token");
        uint256 _balance = _faucetToken.balanceOf(address(this));
        require(_balance >= amount, "Not enough Faucet");
        require(_faucetToken.transfer(msg.sender, amount), "transfer failed");
    }

    //  Batch Claim
    function claimBatch() external {
        for (uint i = 0; i < assetIDs.length; i++) {
            ERC20 _faucetToken = ERC20(tokenMap[assetIDs[i]]);
            require(_faucetToken.balanceOf(msg.sender) < threshold, "You have enough testnet token");
            uint256 _balance = _faucetToken.balanceOf(address(this));
            require(_balance >= amount, "Not enough Faucet");
            require(_faucetToken.transfer(msg.sender, amount), "transfer failed");
        }
    }

    /******
        view functions
    *******/
    function balanceOfFaucet(uint256 _assetID) external view returns(uint256) {
        ERC20 _faucetToken = ERC20(tokenMap[_assetID]);
        return _faucetToken.balanceOf(address(this));
    }

    // withdraw assets to deployer
    function withdraw() public onlyOwner {
        for (uint i = 0; i < assetIDs.length; i++) {
            ERC20 _faucetToken = ERC20(tokenMap[assetIDs[i]]);
            uint256 _balance = _faucetToken.balanceOf(address(this));
            require(_faucetToken.transfer(owner, _balance), "withdraw failed");
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}