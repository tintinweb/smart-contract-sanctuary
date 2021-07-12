/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-07
*/

pragma solidity ^0.7.1;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



//V10.04
contract Fortuna {
    string public name;
    address public manager;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public lpb = block.number;
    uint public datumIndex = 0;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    address[] public holderlist;
    mapping (string => uint256 ) public balances;
    mapping (string => uint256) public unumber;
    mapping (string => uint256) public underover;
    mapping(uint256 => address payable[] ) blockBets;
    using SafeMath for uint;

    mapping (address => User) users;
    mapping (uint => Datumpointlist) dlist;

    struct User {
        uint liq; //ne kadar ile girdim.
        uint dp; //hangi evrede girdim.
    }
    struct Datumpointlist {
       uint liqsum; //evredeki toplam likidite
       uint prosum; //evredeki toplam kar
   }

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        initialSupply = 500000000  * 10 ** uint256(decimals);
        tokenName = "Fortuna";
        tokenSymbol = "FT10.04";
        manager = msg.sender;
        balanceOf[msg.sender] = initialSupply;
        totalSupply =  initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        holderlist.push(address(this)); //we need add first address for transfer works correctly.
    }

    function nMixAddrandBlock()  private view returns(string memory) {
         uint256 _bnum = block.number;
         return append(uintToString(nAddrHash()),uintToString(_bnum));
    }


    function nMixAddrandSpBlock(uint256 bnum)  private view returns(string memory) {
         return append(uintToString(nAddrHash()),uintToString(bnum));
    }

    function nAddrHashO(address _address) view public returns (uint256) {
        return uint256(_address) % 10000000000;
    }

    function nMixAddrandBlockO(address _address)  private view returns(string memory) {
         uint256 _bnum = block.number;
         return append(uintToString(nAddrHashO(_address)),uintToString(_bnum));
    }
    function nMixAddrandSpBlockO(uint256 bnum, address _address)  private view returns(string memory) {
         return append(uintToString(nAddrHashO(_address)),uintToString(bnum));
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint256 onepercentofamount = _value / 100;
        //uint previousBalances = (balanceOf[_from] + balanceOf[_to]);

        burn(onepercentofamount); //%1 burned
        emit Burn(_from, onepercentofamount);

        balanceOf[_from] -= onepercentofamount;
        address _luckyto = holderlist[getblockhash() % numberofholders()];
        balanceOf[_luckyto] += onepercentofamount;// %1 sending some lucky human!
        emit Transfer(_from, _luckyto, onepercentofamount);

        balanceOf[_from] -= onepercentofamount; //%1 sending contract back
        balanceOf[address(this)] += onepercentofamount; //%1 sending contract back
        dlist[datumIndex].prosum  +=  uint(onepercentofamount); //Kazanılan kâr gerekli çağa eklenir!
        emit Transfer(_from, address(this), onepercentofamount);

        balanceOf[_from] -= onepercentofamount*97;
        balanceOf[_to] += onepercentofamount*97;
        emit Transfer(_from, _to, onepercentofamount*97);
        holderlist.push(_to);

        if(lpb != block.number) { //pay old player's
          for (uint256 i=0; i<blockBets[lpb].length; i++) { chashBack(lpb, blockBets[lpb][i]);}lpb = block.number;
        }



        //assert(balanceOf[_from] + balanceOf[_to] == previousBalances - (onepercentofamount*3));
    }

    function _shareholder(address _from, address _to, uint _value) internal {
        
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint256 onepercentofamount = _value / 100;
        //uint previousBalances = (balanceOf[_from] + balanceOf[_to]);

        burn(onepercentofamount); //%1 burned
        emit Burn(_from, onepercentofamount);

        balanceOf[_from] -= onepercentofamount;
        address _luckyto = holderlist[getblockhash() % numberofholders()];
        balanceOf[_luckyto] += onepercentofamount;// %1 sending some lucky human!
        emit Transfer(_from, _luckyto, onepercentofamount);

        balanceOf[_from] -= onepercentofamount; //%1 sending contract back
        balanceOf[address(this)] += onepercentofamount; //%1 sending contract back
        dlist[datumIndex].prosum  +=  uint(onepercentofamount); //Kazanılan kâr gerekli çağa eklenir!
        emit Transfer(_from, address(this), onepercentofamount);

        balanceOf[_from] -= onepercentofamount*97;
        balanceOf[_to] += onepercentofamount*97;
        emit Transfer(_from, _to, onepercentofamount*97);
        holderlist.push(_to);
        //assert(balanceOf[_from] + balanceOf[_to] == previousBalances - (onepercentofamount*3));
        
        
    }

    function _cleantransfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }



    function getblockhash() public view returns (uint256) {
            return uint256(blockhash(block.number-1));
    }

    function numberofholders() view public returns (uint) {
      return holderlist.length;
    }


     function numberofblockplayer(uint256 _bnum) view public returns (uint) {
      return blockBets[_bnum].length;
    }


    function getholderfromid(uint _pid) view public returns (address){
        return holderlist[_pid];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }


   function uintToString(uint256 v) internal pure returns(string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function nAddrHash() view public returns (uint256) {
        return uint256(msg.sender) % 10000000000;
    }


    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"-",b));
    }







   function playagame(uint256 _tokens, uint256 _underover, uint256 _unumber)  public {
            if(_underover == 1 || _underover == 2) {
            if(_unumber > 5 || _unumber < 95) {
            if(balances[nMixAddrandBlock()] == 0) {
            balances[nMixAddrandBlock()] = _tokens;
            underover[nMixAddrandBlock()] = _underover;
            unumber[nMixAddrandBlock()] = _unumber;
            blockBets[block.number].push(msg.sender);
            _transfer(msg.sender, address(this), _tokens);
            } else {revert();}
            } else {revert();}
            } else {revert();}
  }


    function checkReward(uint256 _bnum, address _addr) private view returns(uint) {
         uint _randNumb = (uint256(blockhash(_bnum+1))%100)+1;
         uint _underover = underover[nMixAddrandSpBlockO(_bnum, _addr)];
         uint _selectednumber = unumber[nMixAddrandSpBlockO(_bnum, _addr)];
         uint256 _money = balances[nMixAddrandSpBlockO(_bnum, _addr)];
            if(_underover == 1) {
                if(_randNumb < _selectednumber) {
                     uint _probability = uint(100).sub(_selectednumber);
                     return uint(uint(100).mul(_money)).div(_probability);
                 }
            }else if(_underover == 2) {
                 if(_randNumb > _selectednumber) {
                     uint _probability = uint(100).sub(_selectednumber);
                     return uint(uint(100).mul(_money)).div(_probability);
                 }
                } else {return 0;}
    }


  function chashBack(uint256 bnum, address payable _addr) public {
         uint whatiearn = checkReward(bnum, _addr);
         if(balances[nMixAddrandSpBlockO(bnum, _addr)] != 0 && whatiearn != 0) {
           _shareholder(address(this), _addr, whatiearn);
           balances[nMixAddrandSpBlockO(bnum, _addr)] = 0;
         }
  }





 //struct User {
 //   uint256 liq; //ne kadar ile girdim.
 //     uint256 dp; //hangi evrede girdim.
 //}
 //struct Datumpointlist {
 //    uint256 liqsum; //evredeki toplam likidite
 //    uint256 prosum; //evredeki toplam kar
 //}
 //mapping (address => User) users;
 //mapping (uint256 => Datumpointlist) dlist;


 function depositeFortuna(uint256 tokens) public {
        require(tokens > 1 * 10 ** decimals); //minimum one token require
        require(users[msg.sender].dp == 0);
        datumIndex++;
        if(datumIndex == 0) {
            users[msg.sender] = User(uint(tokens), datumIndex);
            dlist[datumIndex].liqsum =  uint(tokens);

        _cleantransfer(msg.sender, address(this), tokens);
        } else {
            users[msg.sender] = User(uint(tokens), datumIndex);
            dlist[datumIndex].liqsum =  dlist[datumIndex-1].liqsum + uint(tokens);

            _cleantransfer(msg.sender, address(this), tokens);
        }




 }

function calculateUserShare(address _addr) public view returns(uint) {

  if(users[_addr].liq == 0) {
      return 0;
  } else {
      uint  totalReward = 0;
      for (uint i=users[_addr].dp; i<=datumIndex; i++) {
         uint profitRate =  users[_addr].liq.mul(100).div(dlist[i].liqsum);
         totalReward += profitRate.mul(dlist[i].prosum.div(100));
      }
      return totalReward;
  }
}

function removeLiqudity() public {
    require(users[msg.sender].liq != 0);
    uint usershare = calculateUserShare(msg.sender);
    datumIndex++;
    dlist[datumIndex].liqsum =  dlist[datumIndex-1].liqsum - users[msg.sender].liq;
    _cleantransfer(address(this), msg.sender, usershare + users[msg.sender].liq);
    users[msg.sender] = User(0,0);
 }

 function checkusers(address _addr) public view returns (uint256, uint256){
         return (users[_addr].liq, users[_addr].dp);
  }

  function checkdlist(uint256 _val) public view returns (uint256, uint256){
        return (dlist[_val].liqsum ,dlist[_val].prosum);
    }
 }