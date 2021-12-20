pragma solidity 0.5.8;

import "./SmartToken.sol";

contract BridgeToken is SmartToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor() public {
        _name = "Bridge Oracle";
        _symbol = "BRG";
        _decimals = 6;
        mint(msg.sender, 10000000000e6);
    }

    /**
     * @dev Returns name of the token.
    */

    function name() public view returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns symbol of the token.
    */

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns decimals of the token.
     */

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    event Freeze(address indexed from, address indexed to, uint256 value);
    event Melt(address indexed from ,address indexed to, uint256 value);
    
    /**
     * @dev transfer frozen tokens to a specified address
     * @param to is the address to which frozen tokens are transfered.
     * @param value is the frozen amount which is transferred.
     */

    function freeze(address to, uint256 value) public onlyOwner stoppable returns(bool) {
        _freeze(msg.sender, to, value);
        return true;
    }

    function _freeze(address _from, address to, uint256 value) private {
        Frozen[to] = Frozen[to].add(value);
        _transfer(_from, to, value);
        emit Freeze(_from ,to, value);
    }

    /**
     * @dev melt frozen tokens of specified address
     * @param to is the address from which frozen tokens are molten.
     * @param value is the frozen amount which is molten.
     */
    
    function melt(address to, uint256 value) public  onlyOwner stoppable returns(bool) {
        _melt(msg.sender, to, value);
        return true;
    }
    
    function _melt(address _onBehalfOf, address to, uint256 value) private {
        require(Frozen[to] >= value);
        Frozen[to] = Frozen[to].sub(value);
        emit Melt(_onBehalfOf, to, value);
    }
    
    function transferAnyERC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        ITRC20(_tokenAddress).transfer(_to, _amount);
    }


    function withdrawBNB() public onlyOwner returns(bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }
}