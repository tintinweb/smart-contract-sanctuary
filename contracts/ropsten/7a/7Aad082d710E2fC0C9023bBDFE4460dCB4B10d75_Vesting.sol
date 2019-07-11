/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract Vesting {

    using SafeMath for uint256;

    ERC20 public mycroToken;

    event LogFreezedTokensToInvestor(address _investorAddress, uint256 _tokenAmount, uint256 _daysToFreeze);
    event LogUpdatedTokensToInvestor(address _investorAddress, uint256 _tokenAmount);
    event LogWithdraw(address _investorAddress, uint256 _tokenAmount);

    constructor(address _token) public {
        mycroToken = ERC20(_token);
    }

    mapping (address => Investor) public investors;

    struct Investor {
        uint256 tokenAmount;
        uint256 frozenPeriod;
        bool isInvestor;
    }


    /**
        @param _investorAddress the address of the investor
        @param _tokenAmount the amount of tokens an investor will receive
        @param _daysToFreeze the number of the days token would be freezed to withrow, e.c. 3 => 3 days
     */
    function freezeTokensToInvestor(address _investorAddress, uint256 _tokenAmount, uint256 _daysToFreeze) public returns (bool) {
        require(_investorAddress != address(0));
        require(_tokenAmount != 0);
        require(!investors[_investorAddress].isInvestor);

        _daysToFreeze = _daysToFreeze.mul(1 days); // converts days into seconds
        
        investors[_investorAddress] = Investor({tokenAmount: _tokenAmount, frozenPeriod: now.add(_daysToFreeze), isInvestor: true});
        
        require(mycroToken.transferFrom(msg.sender, address(this), _tokenAmount));
        emit LogFreezedTokensToInvestor(_investorAddress, _tokenAmount, _daysToFreeze);

        return true;
    }

     function updateTokensToInvestor(address _investorAddress, uint256 _tokenAmount) public returns(bool) {
        require(investors[_investorAddress].isInvestor);
        Investor storage currentInvestor = investors[_investorAddress];
        currentInvestor.tokenAmount = currentInvestor.tokenAmount.add(_tokenAmount);

        require(mycroToken.transferFrom(msg.sender, address(this), _tokenAmount));
        emit LogUpdatedTokensToInvestor(_investorAddress, _tokenAmount);

        return true;
    }

    function withdraw(uint256 _tokenAmount) public {
        address investorAddress = msg.sender;
        Investor storage currentInvestor = investors[investorAddress];
        
        require(currentInvestor.isInvestor);
        require(now >= currentInvestor.frozenPeriod);
        require(_tokenAmount <= currentInvestor.tokenAmount);

        currentInvestor.tokenAmount = currentInvestor.tokenAmount.sub(_tokenAmount);
        require(mycroToken.transfer(investorAddress, _tokenAmount));
        emit LogWithdraw(investorAddress, _tokenAmount);
    }



}