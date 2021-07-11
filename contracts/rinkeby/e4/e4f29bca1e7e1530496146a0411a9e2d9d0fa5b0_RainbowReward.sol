pragma solidity 0.6.0;
import "./ERC20Interface.sol";
import "./SafeMath.sol";
import "./RainbowInterface.sol";
import "./RainbowuRBInterface.sol";
import "./RoleManageContract.sol";

contract RainbowReward is RoleManageContract{

    using SafeMath for uint256;

    address public rbTokenAddress;
    address public uRBTokenAddress;
    address public usdtTokenAddress;

    uint256 public totalRevenue;

    struct ProjectModuleStruct {
        uint256 totalModelCount;
        //10:Have authority
        mapping(address => uint256) modulePermissions;
    }
    ProjectModuleStruct public moduleManager;

    constructor() public{
        _owner = msg.sender;
        moduleManager = ProjectModuleStruct({totalModelCount:0});
        totalRevenue = 0;
    }

    function setRBTokenAddress(address _token)public onlyOwner {
        require(_token != address(0),"setRBTokenAddress## set address error !");
        rbTokenAddress = _token;
    }

    function setuRBTokenAddress(address _token)public onlyOwner {
        require(_token != address(0),"setuRBTokenAddress## set address error !");
        uRBTokenAddress = _token;
    }

    function setUsdtTokenAddress(address _token)public onlyOwner {
        require(_token != address(0),"setUsdtTokenAddress## set address error !");
        usdtTokenAddress = _token;
    }

    function setModuleAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"setModuleAddress## module error .");
        uint256 authority = moduleManager.modulePermissions[_addr];
        require(authority != 10,"setModuleAddress## Has authorized .");
        moduleManager.modulePermissions[_addr] = 10;
        moduleManager.totalModelCount = moduleManager.totalModelCount.add(1);
    }

    function removeModuleAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"removeModuleAddress## module error .");
        uint256 authority = moduleManager.modulePermissions[_addr];
        require(authority == 10,"removeModuleAddress## No Authority .");
        moduleManager.modulePermissions[_addr] = 0;
        moduleManager.totalModelCount = moduleManager.totalModelCount.sub(1);
    }


    function getModulePermission(address module) private view returns(bool){
        uint256 authority = moduleManager.modulePermissions[module];
        if(authority == 10){
            return true;
        }else{
            return false;
        }
    }

    function increaseIncome(uint256 income)public returns(bool){
        require(getModulePermission(msg.sender),"increaseIncome## address error !");
        require(income > 0,"increaseIncome## income 0, error !");
        totalRevenue = totalRevenue.add(income);
        return true;
    }

    function getTotalRevenue()public view returns(uint256) {
        return totalRevenue;
    }

    //Exchange, recycling token
    function recycleRB(address _receive)public onlyOwner {
        require(_receive != address(0),"recycleRB## Receive address error .");
        require(usdtTokenAddress != address(0),"recycleRB## usdtTokenAddress address error .");
        ERC20 usdt = ERC20(usdtTokenAddress);
        require(usdt.balanceOf(address(this)) > 0,"recycleRB## usdt balance 0 .");
        require(usdt.transfer(_receive,usdt.balanceOf(address(this))),"recycleRB## transfer error .");
    }

    //Stake $RB to exchange for uRB
    function stakeRB(uint256 quantity)public returns(bool){
        
        require(rbTokenAddress != address(0),"stakeRB## rbTokenAddress error !");
        require(uRBTokenAddress != address(0),"stakeRB## uRBTokenAddress error !");
        require(usdtTokenAddress != address(0),"stakeRB## usdtTokenAddress error !");
        Rainbow rb = Rainbow(rbTokenAddress);
        Rainbow_uRB uRB = Rainbow_uRB(uRBTokenAddress);
        require(uRB.balanceOf(msg.sender) == 0,"stakeRB## uRB is exist !");
        require(rb.balanceOf(msg.sender)>=quantity,"stakeRB## Insufficient balance !");

        uint256 rbApproveAmount = rb.allowance(msg.sender,address(this));
        require(rbApproveAmount >= quantity,"stakeRB## approve error !");
        require(rb.transferFrom(msg.sender,address(this),quantity),"stakeRB## transferFrom error !");

        uRB.mintTokenAmount(quantity,totalRevenue,msg.sender);

        return true;
    }


    //Receive award
    function withdrawAssets()public returns(bool){
        require(rbTokenAddress != address(0),"withdrawAssets## rbTokenAddress error !");
        require(uRBTokenAddress != address(0),"withdrawAssets## uRBTokenAddress error !");
        require(usdtTokenAddress != address(0),"withdrawAssets## usdtTokenAddress error !");
        ERC20 usdt = ERC20(usdtTokenAddress);
        Rainbow rb = Rainbow(rbTokenAddress);
        Rainbow_uRB uRB = Rainbow_uRB(uRBTokenAddress);

        require(uRB.balanceOf(msg.sender) > 0,"withdrawAssets## uRB is 0 .");

        uint256 effectiveRewardUsdt = totalRevenue.sub(uRB.rewardStartbalanceOf(msg.sender));
        uint256 total_URB = uRB.totalSupply().div(1e18);
        uint256 user_URB = uRB.balanceOf(msg.sender).div(1e18);
        uint256 rewardUsdt = mulDiv(effectiveRewardUsdt,user_URB,total_URB);
        usdt.transfer(msg.sender,rewardUsdt);
        
        rb.burn(uRB.balanceOf(msg.sender));
        uRB.burnTokenAmount(msg.sender);
        return true;
    }

    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

     function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }
}