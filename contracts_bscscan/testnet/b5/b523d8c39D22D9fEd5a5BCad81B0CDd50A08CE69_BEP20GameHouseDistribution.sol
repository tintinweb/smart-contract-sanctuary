/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract BEP20GameHouseDistribution{
    
    using SafeMath for uint256;
     
    address public owner;
     
    uint256 percentHelper=10000;
    
    mapping(address=>bool) public isSupportToken;
    
    address[] public tokens;
    
    
    struct distribution{
        uint256  rewardPercent;
        uint256  burnTokenPercent;
        uint256  daoTreasuryBankRollPercent;  
    }
    
   
    mapping(address=>distribution) public tokenPercentageDistribution;
    
    address public dao;
    address public rewardAddress;
     
     
    modifier restricted() {
        require(msg.sender==owner);
        _;
    } 
     
     
    constructor(address _dao,address _rewardAddress) public{
        dao=_dao;
        rewardAddress=_rewardAddress;
        owner=msg.sender;
    }
    
    
    function updateToken(address _token,uint256 _rewardPercentage, uint256 _burnTokenPercent , uint256 _daoTreasuryBankRollPercent) external restricted(){
        require(_rewardPercentage+_burnTokenPercent+_daoTreasuryBankRollPercent==percentHelper,"sum of percent should be equal to 10000");
        distribution memory percent=distribution(_rewardPercentage,_burnTokenPercent,_daoTreasuryBankRollPercent);
        tokenPercentageDistribution[_token]=percent;
        if(!isSupportToken[_token]){
            tokens.push(_token);
            isSupportToken[_token]=true;
        }
    }
    
    
    function changeDaoAddress(address _daoAddress)external restricted(){
        dao=_daoAddress;
    }
    
    function changeRewardAddress(address _rewardAddress)external restricted(){
        rewardAddress=_rewardAddress;
    }
     
      // transfer ownership
    
    function transferOwnership(address _newOwner) public restricted(){
        require(_newOwner != address(0) && _newOwner != 0x000000000000000000000000000000000000dEaD);
        owner = _newOwner;
    }
    
    function tokenDistribution(address[] memory _token)public restricted(){
        require(_token.length<20,"Only 20 tokens are allowed at a time");
        for(uint i=0;i<_token.length;i++){
             distribution memory percent=tokenPercentageDistribution[_token[i]];
             uint amount=IERC20(_token[i]).balanceOf(address(this));
             uint rewardPart;
             uint burnPart;
             uint daoPart;
             if(amount>0){
               if(percent.rewardPercent>0){
                   rewardPart=amount.mul(percent.rewardPercent).div(percentHelper);
                   TransferHelper.safeTransfer(address(_token[i]),rewardAddress,rewardPart);
                }
               if(percent.burnTokenPercent>0){
                  burnPart=amount.mul(percent.burnTokenPercent).div(percentHelper);
                  TransferHelper.safeTransfer(address(_token[i]),address(0x000000000000000000000000000000000000dEaD),burnPart);
                }
               if(percent.daoTreasuryBankRollPercent>0){
                  daoPart=amount.mul(percent.daoTreasuryBankRollPercent).div(percentHelper);
                  TransferHelper.safeTransfer(address(_token[i]),dao,daoPart);
                }
             }
            emit distributionOccured(_token[i],rewardPart,burnPart,daoPart);
        }  
    }
    
    function recovertoken(address _token) external restricted(){
        TransferHelper.safeTransfer(address(_token),owner , IERC20(_token).balanceOf(address(this)));
    }

    function recoverBNB()external restricted(){
        payable(owner).transfer(address(this).balance); 
    }
   
    function getTokens()public view returns(address[] memory){
        return tokens;
    }

    event distributionOccured(address Token,uint Reward,uint Burn,uint DAO);

}