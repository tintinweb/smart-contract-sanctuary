// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ManorToken {

    using SafeMath for uint256;

    address public _owner  = 0x8cd0B8941AF4199787A3A93510Fe41534D50e189;
    address public _realtor = 0x9E9b841f19a6Fc5E20c3b4C26Ec113e4C4D040e3;
    uint256 public end;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Purchase(address indexed buyer, uint256 tokens, uint256 eth);

    string public constant name = "Manor Token";
    string public constant symbol = "MT";
    uint256 public constant decimals = 18;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0) / 1000000000000000000;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 totalGons = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = 21000000 * 10**DECIMALS;  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _totalDeposit;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;

    uint256 public dollar = uint256(1 ether).div(2100);
    uint256 public basePrice = dollar.div(10);
    uint256 public priceIncrement = dollar.div(100);

    mapping(address => address) public referrer;
    mapping(address => uint256) public refBalances;

    constructor() public {
      end = block.timestamp + (55 * 86400); // 55 days
      _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
      _gonBalances[_owner] = TOTAL_GONS;
      _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

      emit Transfer(address(0), _owner, _totalSupply);
    }

    function isEnded() public view returns(bool) {
        return (block.timestamp >= end || _totalDeposit >= dollar.mul(21000000));
    }

    function _mint(address _user, uint256 _amount) internal{
      _gonBalances[_user] = _gonBalances[_user].add(_amount.mul(_gonsPerFragment));
      totalGons = totalGons.add(_amount.mul(_gonsPerFragment));
      _totalSupply = _totalSupply.add(_amount);
      _gonsPerFragment = totalGons.div(_totalSupply);
      emit Transfer(address(0), _user, _amount);
    }

    function _payRefs(address _user, address _ref, uint256 _amount) internal {
      _mint(_realtor, _amount.div(20));
      if(referrer[_user] != address(0)){
        refBalances[referrer[_user]] += _amount.div(20);
      }
      else if(_ref != address(0)){
        referrer[_user] = _ref;
        refBalances[referrer[_user]] += _amount.div(20);
      }
    }

    function hardcap() public view returns(uint256){
      return dollar.mul(21000000);
    }

    function updateDollar(uint256 _usdPrice) public onlyOwner {
      dollar = uint256(1 ether).div(_usdPrice);
      basePrice = dollar.div(10);
      priceIncrement = dollar.div(100);
    }

    function calcPrice(uint256 _tokens) public view returns(uint256 _eth){
      uint256 rev = _totalDeposit.div(dollar);
      uint256 remainder = 100000 - (rev.mod(100000));
      uint256 curPrice = basePrice.add(priceIncrement.mul(rev.div(100000)));

      if(_tokens.mul(curPrice).div(dollar) > remainder){
        _eth = remainder.mul(dollar);
        _tokens = _tokens.sub(remainder.mul(dollar).div(curPrice));
        for(uint256 x = 0; x < 21; x++){
          if(x == 20){
            revert("Amount Exceeds HardCap");
          }
          uint256 nextPrice = basePrice.add(priceIncrement.mul(rev.div(100000).add(1 + x)));
          if(_tokens.mul(nextPrice) > dollar.mul(100000)){
            _eth += dollar.mul(100000);
            _tokens = _tokens.sub(dollar.mul(100000).div(nextPrice));
          }
          else{
            _eth += _tokens.mul(nextPrice);
            break;
          }
        }

      }
      else{
        _eth = _tokens.mul(curPrice);
      }
    }

    function calcTokens(uint256 _amount) public view returns(uint256 _tokens){
      uint256 rev = _totalDeposit.div(dollar);
      uint256 remainder = 100000 - (rev.mod(100000));
      uint256 curPrice = basePrice.add(priceIncrement.mul(rev.div(100000)));
      uint256 dollarSpent = _amount.div(dollar);

      if(dollarSpent > remainder){
        _tokens = remainder.mul(dollar).mul(1 ether).div(curPrice);
        _amount = _amount.sub(remainder.mul(dollar));
        for(uint256 x = 0; x < 21; x++){
          if(x == 20){
            revert("Amount Exceeds HardCap");
          }
          uint256 nextPrice = basePrice.add(priceIncrement.mul(rev.div(100000).add(1 + x)));
          if(_amount > dollar.mul(100000)){
            _tokens += dollar.mul(100000).mul(1 ether).div(nextPrice);
            _amount = _amount.sub(dollar.mul(100000));
          }
          else{
            _tokens += _amount.mul(1 ether).div(nextPrice);
            break;
          }
        }
      }
      else{
        _tokens = _amount.mul(1 ether).div(curPrice);
      }

    }

    function purchaseTokens(address _ref) public payable {
      require(!isEnded(), "ICO Ended");
      require(_totalDeposit + msg.value <= dollar.mul(21000000), "Amount Exceeds HardCap");
      uint256 tokensBought = calcTokens(msg.value);

      _payRefs(msg.sender, _ref, tokensBought);
      _totalDeposit += msg.value;

      _mint(msg.sender, tokensBought);
      emit Purchase(msg.sender, tokensBought, msg.value);
    }

    function purchaseExactTokens(address _ref, uint256 _amount) public payable {
      require(!isEnded(), "ICO Ended");
      uint256 tokenPrice = calcPrice(_amount);
      require(msg.value >= tokenPrice, "Insufficient Funds Sent");
      require(_totalDeposit + tokenPrice <= dollar.mul(21000000), "Amount Exceeds HardCap");

      _payRefs(msg.sender, _ref, _amount);
      _totalDeposit += tokenPrice;

      _mint(msg.sender, _amount);
      if(msg.value > tokenPrice){
        msg.sender.transfer(msg.value.sub(tokenPrice));
      }
      emit Purchase(msg.sender, _amount, tokenPrice);
    }

    function claimRefs(uint256 _amount) public {
      require(isEnded(), "ICO Not Ended");
      require(refBalances[msg.sender] >= _amount, "Claim Exceeds Balance");
      refBalances[msg.sender] -= _amount;
      _mint(msg.sender, _amount);
    }

    function clearLiquidity() public onlyOwner{
      require(isEnded(), "ICO Not Ended");
      _mint(msg.sender, _totalSupply);
    }

    function withdrawETH(uint256 _amount) public onlyOwner{
      msg.sender.transfer(_amount);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function totalDeposit()
        public
        view
        returns (uint256)
    {
        return _totalDeposit;
    }

    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue.mul(95).div(100));
        totalGons = totalGons.sub(gonValue.div(20)); // give everyone else 5%
        _gonsPerFragment = totalGons.div(_totalSupply);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue.mul(95).div(100));
        totalGons = totalGons.sub(gonValue.div(20)); // give everyone else 5%
        _gonsPerFragment = totalGons.div(_totalSupply);

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}

