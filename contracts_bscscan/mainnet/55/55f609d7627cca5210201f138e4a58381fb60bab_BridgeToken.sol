pragma solidity 0.8.8;

import "./SmartToken.sol";

contract BridgeToken is SmartToken {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor()  {
        _name = "Bridge";
        _symbol = "BRG";
        _decimals = 18;
        mint(msg.sender, 10000000000e18);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    event Freeze(address indexed from, address indexed to, uint256 value);
    event Melt(address indexed from ,address indexed to, uint256 value);

    function freeze(address to, uint256 value) public onlyOwner stoppable returns(bool) {
        _freeze(msg.sender, to, value);
        return true;
    }

    function _freeze(address _from, address to, uint256 value) private {
        Frozen[to] = Frozen[to].add(value);
        _transfer(_from, to, value);
        emit Freeze(_from ,to, value);
    }
    
    function melt(address to, uint256 value) public  onlyOwner stoppable returns(bool) {
        _melt(msg.sender, to, value);
        return true;
    }
    
    function _melt(address _onBehalfOf, address to, uint256 value) private {
        require(Frozen[to] >= value);
        Frozen[to] = Frozen[to].sub(value);
        emit Melt(_onBehalfOf, to, value);
    }
    
    function transferAnyBEP20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        IBEP20(_tokenAddress).transfer(_to, _amount);
    }

    function withdrawBNB() public onlyOwner returns(bool) {
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
}