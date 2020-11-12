pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./DyDxFlashLoan.sol";
import "./IOneSplitMulti.sol";
import "./SafeMath.sol";

contract DyDxFlashloanArbMulti is DyDxFlashLoan {
    using SafeMath for uint256;
    address arbOwner;
    address constant OneSplitAddress =  0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e;
    address constant RetAddress1 = 0xE365CEf2A7b4B0e4821453570De3A5D8149A32BE;//reward
    address constant RetAddress2 = 0x37fb57eFFa51dDee798E948A05C6b3AC77846b70;//reward

    constructor() public payable {
        arbOwner = msg.sender;
    }
    
    modifier onlyOwner () {
        require(msg.sender == arbOwner, "fail 0");
        _;
    }

    function () external payable {}

    function getFlashloan(address _flashToken, uint256 _flashAmount, address _token, uint256 _returnAmount, uint256[] calldata _distribution, uint256 _flag) external onlyOwner {
        bytes memory _data = abi.encode(_flashToken, _flashAmount, _token, _returnAmount, _distribution, _flag);
        
        flashloan(_flashToken, _flashAmount, _data); //callFunction
    }
    
    function callFunction(address, Info calldata, bytes calldata _data) external onlyPool {
        (address flashToken, uint256 flashAmount, address token, uint256 returnAmount, uint256[] memory distribution, uint256 flag)
        = abi.decode(_data, (address, uint256, address, uint256, uint256[], uint256));
        
        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));
        require(balanceAfter >= flashAmount, "fail 00");
        
        swap1(flashToken, token, flashAmount, returnAmount, distribution, flag);
    }



    function swap1(address from, address token, uint256 amountWei, uint256 returnAmount, uint256[] memory distribution, uint256 flag) internal {
        IERC20 fromERC20 = IERC20(from);
        IERC20 tokenERC20 = IERC20(token);
        
        require(fromERC20.approve(OneSplitAddress, amountWei.add(amountWei)), "fail 1");
        require(tokenERC20.approve(OneSplitAddress, returnAmount.add(returnAmount)), "fail 2");
        
        IERC20[] memory tokensArray = new IERC20[](3);
        tokensArray[0] = fromERC20;
        tokensArray[1] = tokenERC20;
        tokensArray[2] = fromERC20;
        
        uint256[] memory flagsArray = new uint256[](2);
        flagsArray[0] = flag;
        flagsArray[1] = flag;
        
        IOneSplitMulti(OneSplitAddress).swapMulti(tokensArray, amountWei, 0, distribution, flagsArray);
        
        uint256 retval = fromERC20.balanceOf(address(this));
        require(retval > amountWei, "fail 3");
        
        uint256 divval = retval.sub(amountWei.add(1)).div(2);
        fromERC20.transfer(RetAddress1, divval);
        fromERC20.transfer(RetAddress2, divval);
    }
}