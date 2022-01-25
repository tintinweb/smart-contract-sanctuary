// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface IdexRouter02{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path)
    external view
    returns (uint[] memory amounts);
}
interface ISAGToken {
    function walletAGate() external view returns(uint256);
    function walletBGate() external view returns(uint256);
    function fatherGate() external view returns(uint256);
    function grandFatherGate() external view returns(uint256);
    function brunGate() external view returns(uint256);
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract buyToken is Ownable{
    address USDT;
    address SAGToken;
    IdexRouter02 router02 = IdexRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);


    function init(address _SAGtoken, address _USDT, address _router02) public onlyOwner() {
        SAGToken = _SAGtoken;
        USDT = _USDT;
        router02 = IdexRouter02(_router02);
        IERC20(SAGToken).approve(address(router02), uint256(-1));
        IERC20(USDT).approve(address(router02), uint256(-1));
    }

    function buy(address _father, uint256 _amount) public {
        _buy(_amount);
    }

    function sell(address _father, uint256 _amount) public {
        _sell(_amount);
    }

    function buy(uint256 _amount) public {
        _buy(_amount);
    }

    function sell(uint256 _amount) public {
        _sell(_amount);
    }


    function _buy(uint256 _amount) internal {
        IERC20(USDT).transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = SAGToken;

        router02.swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp);
    }

    function _sell(uint256 _amount) internal {
        IERC20(SAGToken).transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path[0] = SAGToken;
        path[1] = USDT;

        _amount = IERC20(SAGToken).balanceOf(address(this));
        router02.swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp); //TODO
    }


    function getPrice(address _token, uint256 _amount) public view returns(uint256){

        address[] memory path = new address[](2);
        uint256 gate = ISAGToken(SAGToken).walletAGate()+
        ISAGToken(SAGToken).walletBGate()+
        ISAGToken(SAGToken).fatherGate()+
        ISAGToken(SAGToken).grandFatherGate()+
        ISAGToken(SAGToken).brunGate()
        ;
        uint256[] memory result;
        uint256 end;
        if(_token == SAGToken){
            path[0] = SAGToken;
            path[1] = USDT;
            _amount = _amount * (100 - gate) / (10**2);
            result = router02.getAmountsOut(_amount, path);
            end = result[1];
        }else{
            path[0] = USDT;
            path[1] = SAGToken;
            result = router02.getAmountsOut(_amount, path);
            end = result[1] * (100 - gate) / (10**2);
        }
        return end;
    }

}