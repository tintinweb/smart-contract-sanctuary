/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

pragma solidity ^0.7.4;
interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;}
contract ERC20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract yieldFarmer {
    address creator;
    uint8 public decimals = 18;
    uint8 public tetherDecimal = 6;
    uint64 public blockTime = 180000;
    address erushLPtoken = 0x88B96ad151D86AAb2367292f53e53C8eaF12dFa3;
    address tetherAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    event NewFarmer(address indexed from, uint256 value);
    event RemoveLiq(address indexed from, uint256 value);
    using SafeMath for uint;
    constructor() {creator = msg.sender;}
    
    struct fdetailz {
       uint256 _amount;
       uint256 _block;
   }
   
    mapping(address => fdetailz) fdetails;
    
    function importUSDT(uint256 _tokens)  public {
        uint256 rma = _tokens * 10 ** uint256(tetherDecimal);
        require(ERC20(tetherAddress).balanceOf(msg.sender) >= _tokens);
        ERC20(tetherAddress).transferFrom(msg.sender, address(this), rma);
    }



    function startFarming(uint256 _tokens)  public {
        //200 LP token provider can reach 50 usdt -> direct proportion with 200&50;
        uint256 rma = _tokens.mul(10 ** uint256(decimals));
        require(rma > 1 * 10 ** uint256(decimals)); //minimum 1 LPtoken require
        require(ERC20(erushLPtoken).balanceOf(msg.sender) >= rma);
        require(fdetails[msg.sender]._amount == 0);
        ERC20(erushLPtoken).transferFrom(msg.sender, address(this), rma);
        uint256 myusdtincome = _tokens.mul(50).div(150);
        ERC20(tetherAddress).transfer(msg.sender, myusdtincome * 10 ** uint256(tetherDecimal) );
        fdetails[msg.sender] = fdetailz(rma, block.number);
        emit NewFarmer(msg.sender, _tokens);
    }
    
    function stopFarming() public {
        require(fdetails[msg.sender]._amount != 0);
        require(block.number - fdetails[msg.sender]._block >= blockTime);
        ERC20(erushLPtoken).transfer(msg.sender, fdetails[msg.sender]._amount);
        emit RemoveLiq(msg.sender, fdetails[msg.sender]._amount.div(10 ** uint256(decimals)));
        fdetails[msg.sender] = fdetailz(0, 0);
    }
   
    function transferOwnership(address newOwner) public {
        require(msg.sender == creator);   // Check if the sender is manager
        if (newOwner != address(0)) {
            creator = newOwner;
        }
    }
    
    function showMyBloks(address _addr) public view returns(uint256) {
        return block.number - fdetails[_addr]._block;
    }
    
    
    function showMyBalance(address _addr) public view returns(uint256) {
        return   fdetails[_addr]._amount.div(10 ** uint256(decimals));
    }
    
    function withdrawal(uint tokens)  public {
        require(msg.sender == creator); 
        ERC20(erushLPtoken).transfer(creator, tokens);
    }
    
    function withdrawalUSDT(uint tokens)  public {
        require(msg.sender == creator); 
        ERC20(tetherAddress).transfer(creator, tokens);
    }
}