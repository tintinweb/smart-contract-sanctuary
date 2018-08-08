contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Arithmetic {
    function mul256By256(uint a, uint b)
        constant
        returns (uint ab32, uint ab1, uint ab0)
    {
        uint ahi = a >> 128;
        uint alo = a & 2**128-1;
        uint bhi = b >> 128;
        uint blo = b & 2**128-1;
        ab0 = alo * blo;
        ab1 = (ab0 >> 128) + (ahi * blo & 2**128-1) + (alo * bhi & 2**128-1);
        ab32 = (ab1 >> 128) + ahi * bhi + (ahi * blo >> 128) + (alo * bhi >> 128);
        ab1 &= 2**128-1;
        ab0 &= 2**128-1;
    }

    // I adapted this from Fast Division of Large Integers by Karl Hasselstr&#246;m
    // Algorithm 3.4: Divide-and-conquer division (3 by 2)
    // Karl got it from Burnikel and Ziegler and the GMP lib implementation
    function div256_128By256(uint a21, uint a0, uint b)
        constant
        returns (uint q, uint r)
    {
        uint qhi = (a21 / b) << 128;
        a21 %= b;

        uint shift = 0;
        while(b >> shift > 0) shift++;
        shift = 256 - shift;
        a21 = (a21 << shift) + (shift > 128 ? a0 << (shift - 128) : a0 >> (128 - shift));
        a0 = (a0 << shift) & 2**128-1;
        b <<= shift;
        var (b1, b0) = (b >> 128, b & 2**128-1);

        uint rhi;
        q = a21 / b1;
        rhi = a21 % b1;

        uint rsub0 = (q & 2**128-1) * b0;
        uint rsub21 = (q >> 128) * b0 + (rsub0 >> 128);
        rsub0 &= 2**128-1;

        while(rsub21 > rhi || rsub21 == rhi && rsub0 > a0) {
            q--;
            a0 += b0;
            rhi += b1 + (a0 >> 128);
            a0 &= 2**128-1;
        }

        q += qhi;
        r = (((rhi - rsub21) << 128) + a0 - rsub0) >> shift;
    }

    function overflowResistantFraction(uint a, uint b, uint divisor)
        returns (uint)
    {
        uint ab32_q1; uint ab1_r1; uint ab0;
        if(b <= 1 || b != 0 && a * b / b == a) {
            return a * b / divisor;
        } else {
            (ab32_q1, ab1_r1, ab0) = mul256By256(a, b);
            (ab32_q1, ab1_r1) = div256_128By256(ab32_q1, ab1_r1, divisor);
            (a, b) = div256_128By256(ab1_r1, ab0, divisor);
            return (ab32_q1 << 128) + a;
        }
    }
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




contract Presale is Ownable, SafeMath, Arithmetic  {
    uint public minInvest = 10 ether;
    uint public maxcap = 490 ether;   // 100k euro based on kraken rates on 27/06/2017 at 13h20
    address public ledgerWallet = "0xa4dbbF474a6f026Cf0a2d3e45aB192Fbd98D3a5f";
    uint public count = 0;
    uint public totalFunding;
    bool public saleOn;
    bool public distributed;
    address public crowdsaleContract;
    uint public balanceToken;
    address[] public listBackers;
    mapping (address => uint) public backers;
    ERC20 public DTR;                       // wait to be instantiate when ERC20 will be created
    event ReceivedETH(address addr, uint value);
    event Logs(address addr, uint value1, uint value2);
    event Logs2(uint value1, uint value2,uint value3, uint value4,uint value5, uint value6);
    function Presale () {
        saleOn = true;
        distributed = false;
    }
    function() payable {
        require(saleOn);
        require(msg.value > minInvest);
        require( SafeMath.add(totalFunding, msg.value) <= maxcap);
        if (backers[msg.sender] == 0)
          listBackers.push(msg.sender);
        backers[msg.sender] =  SafeMath.add(backers[msg.sender], msg.value);
        totalFunding = SafeMath.add(totalFunding, msg.value);
        ledgerWallet.transfer(this.balance);
        ReceivedETH(msg.sender, msg.value);
    }
    function balanceOf(address _owner) constant returns (uint balance) {
      return backers[_owner];
    }
    function setDTR (address dtrAddress) onlyOwner {
        DTR = ERC20(dtrAddress);
        balanceToken = DTR.balanceOf(this);
        Logs(dtrAddress, balanceToken, this.balance);
    }

    function withdraw() onlyOwner {
        ledgerWallet.transfer(this.balance);
    }

    function closeSale() onlyOwner {
        saleOn = false;
    }

    // when closing ICO, token will be send to this contract, then this function will be called and token will be distribute among early investor
    function distributes(uint max) onlyOwner {
        require(!saleOn);
        while(count < max) {
            uint toSend = Arithmetic.overflowResistantFraction(balanceToken, backers[listBackers[count]], totalFunding);
            require(DTR.transfer(listBackers[count], toSend));
            count++;
            if (count == listBackers.length) {
                distributed = true;
                break ;
            }
        }
    }
}