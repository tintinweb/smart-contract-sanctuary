/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

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
        external
        view
        returns (uint[] memory amounts);
}
interface relationship {
    function father(address _son) external view returns(address);
    function otherCallSetRelationship(address _son, address _father) external;
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
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
    address USDT = 0xc85af79f1D27f518Cd05e34f33cEe33D4444Af1E;
    address SAGToken;
    relationship RP;
    IdexRouter02 router02 = IdexRouter02(0xA1Af6c8399DAf63f3E2EC4C175cF45a7ba5816AE);
    
    
    function init(address _token, address _rp) public onlyOwner() {
        SAGToken = _token;
        RP = relationship(_rp);
        
        IERC20(SAGToken).approve(address(router02), uint256(-1));
        IERC20(USDT).approve(address(router02), uint256(-1));
    }
    
    function buy(address _father, uint256 _amount) public {
        if (RP.father(msg.sender) == address(0)){
            RP.otherCallSetRelationship(msg.sender, _father);
        }
        _buy(_amount);
    }

    function sell(address _father, uint256 _amount) public {
        if (RP.father(msg.sender) == address(0)){//如果没有绑定推荐关系，就在这里绑定 否则跳过
            RP.otherCallSetRelationship(msg.sender, _father);
        }
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
        IERC20(SAGToken).transferFrom(msg.sender, address(this), _amount);//代币代理转账到本合约时，就已经

        address[] memory path = new address[](2);
        path[0] = SAGToken;
        path[1] = USDT;

        _amount = IERC20(SAGToken).balanceOf(address(this));
        router02.swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp); //TODO 
    }


    function getPrice(address _token, uint256 _amount) public view returns(uint256){

            address[] memory path = new address[](2);
            uint256 gate = ISAGToken(SAGToken).walletAGate() +
                           ISAGToken(SAGToken).walletBGate() +
                           ISAGToken(SAGToken).fatherGate() +
                           ISAGToken(SAGToken).grandFatherGate() +
                           ISAGToken(SAGToken).brunGate()
                           ;
            uint256[] memory result;
            uint256 num;
            if(_token == SAGToken){
                path[0] = SAGToken;
                path[1] = USDT;
                _amount = _amount * (100 - gate) / (10**2);
                result= router02.getAmountsOut(_amount, path);
                num = result[1];
            }else{
                path[0] = USDT;
                path[1] = SAGToken;
                result = router02.getAmountsOut(_amount, path);
                num = result[1] * (100 - gate) / (10**2);
            }
            return num;
    }

}