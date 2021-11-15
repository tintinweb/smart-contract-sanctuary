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

    address public owner;//  = 0x8cd0B8941AF4199787A3A93510Fe41534D50e189;
    address public realtor;// = 0x9E9b841f19a6Fc5E20c3b4C26Ec113e4C4D040e3;
    uint256 public end;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Purchase(address indexed buyer, uint256 tokens, uint256 eth);
    event PriceUpdate(uint256 _dollar);

    string public constant name = "Manor Token";
    string public constant symbol = "MT";
    uint256 public constant decimals = 18;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0) / 1000000000000000000;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 totalGons = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _totalDeposit;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;

    uint256 public dollar;
    uint256 public basePrice;
    uint256 public priceIncrement;

    mapping(address => address) public referrer;
    mapping(address => uint256) public refBalances;

    constructor(address _owner, address _realtor, uint256 _dollarPrice) {
      require(_owner != address(0), "Invalid Address");
      require(_realtor != address(0), "Invalid Address");

      owner = _owner;
      realtor = _realtor;
      _updateDollar(_dollarPrice);

      end = block.timestamp + (50 * 86400); // 55 days
      _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
      _gonBalances[owner] = TOTAL_GONS;
      _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

      emit Transfer(address(0), owner, _totalSupply);
    }

    function hardcap() public view returns(uint256){
      return dollar.mul(21000000);
    }

    function isEnded() public view returns(bool) {
        return (block.timestamp >= end || _totalDeposit >= hardcap());
    }

    function _mint(address _user, uint256 _amount) internal{
      _gonBalances[_user] = _gonBalances[_user].add(_amount.mul(_gonsPerFragment));
      totalGons = totalGons.add(_amount.mul(_gonsPerFragment));
      _totalSupply = _totalSupply.add(_amount);
      _gonsPerFragment = totalGons.div(_totalSupply);
      emit Transfer(address(0), _user, _amount);
    }

    function _payRefs(address _user, address _ref, uint256 _amount) internal {
      _mint(realtor, _amount.div(20));
      if(referrer[_user] != address(0)){
        refBalances[referrer[_user]] += _amount.div(20);
      }
      else if(_ref != address(0)){
        referrer[_user] = _ref;
        refBalances[referrer[_user]] += _amount.div(20);
      }
    }

    function _updateDollar(uint256 usdPrice) internal {
      require(usdPrice != 0, "Invalid Price");
      dollar = uint256(1 ether).div(usdPrice);
      basePrice = dollar.div(10);
      priceIncrement = dollar.div(100);
      emit PriceUpdate(dollar);
    }

    function updateDollar(uint256 usdPrice) public onlyOwner {
      _updateDollar(usdPrice);
    }

    function calcPrice(uint256 tokens) public view returns(uint256 _eth){
      uint256 rev = _totalDeposit.div(dollar);
      uint256 remainder = 100000 - (rev.mod(100000));
      uint256 curPrice = basePrice.add(priceIncrement.mul(rev.div(100000)));

      if(tokens.mul(curPrice).div(dollar) > remainder){
        _eth = remainder.mul(dollar);
        tokens = tokens.sub(remainder.mul(dollar).div(curPrice));
        for(uint256 x = 0; x < 21; x++){
          if(x == 20){
            revert("Amount Exceeds HardCap");
          }
          uint256 nextPrice = basePrice.add(priceIncrement.mul(rev.div(100000).add(1 + x)));
          if(tokens.mul(nextPrice) > dollar.mul(100000)){
            _eth = _eth.add(dollar.mul(100000));
            tokens = tokens.sub(dollar.mul(100000).div(nextPrice));
          }
          else{
            _eth = _eth.add(tokens.mul(nextPrice));
            break;
          }
        }

      }
      else{
        _eth = tokens.mul(curPrice);
      }
    }

    function calcTokens(uint256 amount) public view returns(uint256 _tokens){
      uint256 rev = _totalDeposit.div(dollar);
      uint256 remainder = 100000 - (rev.mod(100000));
      uint256 curPrice = basePrice.add(priceIncrement.mul(rev.div(100000)));
      uint256 dollarSpent = amount.div(dollar);

      if(dollarSpent > remainder){
        _tokens = remainder.mul(dollar).mul(1 ether).div(curPrice);
        amount = amount.sub(remainder.mul(dollar));
        for(uint256 x = 0; x < 21; x++){
          if(x == 20){
            revert("Amount Exceeds HardCap");
          }
          uint256 nextPrice = basePrice.add(priceIncrement.mul(rev.div(100000).add(1 + x)));
          if(amount > dollar.mul(100000)){
            _tokens = _tokens.add(dollar.mul(100000).mul(1 ether).div(nextPrice));
            amount = amount.sub(dollar.mul(100000));
          }
          else{
            _tokens = _tokens.add(amount.mul(1 ether).div(nextPrice));
            break;
          }
        }
      }
      else{
        _tokens = amount.mul(1 ether).div(curPrice);
      }

    }

    function purchaseTokens(address ref) external payable {
      require(!isEnded(), "ICO Ended");
      require(_totalDeposit.add(msg.value) <= hardcap(), "Amount Exceeds HardCap");
      uint256 tokensBought = calcTokens(msg.value);

      _payRefs(msg.sender, ref, tokensBought);
      _totalDeposit += msg.value;

      emit Purchase(msg.sender, tokensBought, msg.value);
      _mint(msg.sender, tokensBought);

    }

    function purchaseExactTokens(address ref, uint256 amount) external payable {
      require(!isEnded(), "ICO Ended");
      uint256 tokenPrice = calcPrice(amount);
      require(msg.value >= tokenPrice, "Insufficient Funds Sent");
      require(_totalDeposit.add(tokenPrice) <= hardcap(), "Amount Exceeds HardCap");

      _payRefs(msg.sender, ref, amount);
      _totalDeposit += tokenPrice;

      _mint(msg.sender, amount);
      emit Purchase(msg.sender, amount, tokenPrice);
      if(msg.value > tokenPrice){
        msg.sender.transfer(msg.value.sub(tokenPrice));
      }
    }

    function claimRefs(uint256 amount) external {
      require(isEnded(), "ICO Not Ended");
      require(refBalances[msg.sender] >= amount, "Claim Exceeds Balance");
      refBalances[msg.sender] -= amount;
      _mint(msg.sender, amount);
    }

    function clearLiquidity() external onlyOwner{
      require(isEnded(), "ICO Not Ended");
      _mint(msg.sender, _totalSupply);
    }

    function withdrawETH(uint256 amount) external onlyOwner{
      msg.sender.transfer(amount);
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function totalDeposit()
        external
        view
        returns (uint256)
    {
        return _totalDeposit;
    }

    function balanceOf(address who)
        external
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        external
        returns (bool)
    {
        require(to != address(0), "Invalid Recipient");
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue.mul(95).div(100));
        totalGons = totalGons.sub(gonValue.div(20)); // give everyone else 5%
        _gonsPerFragment = totalGons.div(_totalSupply);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool)
    {
        require(to != address(0) && from != address(0), "Invalid Recipient/Sender");
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
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
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

