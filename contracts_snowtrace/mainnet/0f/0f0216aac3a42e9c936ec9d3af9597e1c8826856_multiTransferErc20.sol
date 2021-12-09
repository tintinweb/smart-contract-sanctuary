/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract multiTransferErc20 {
    address owner;
    constructor () {
        owner=msg.sender;

    }
    
    function multiTransfer(address _tokenAddress,address[] memory toAddressArr,uint _amount) public  {
        for(uint i=0;i<toAddressArr.length;i++){
            IERC20(_tokenAddress).transferFrom(msg.sender,toAddressArr[i],_amount);
        }
        
    }
    
    
    function multiTransferWithDifferentAmount(address _tokenAddress,address[] memory toAddressArr,uint[] memory _amountArr) public  {
        for(uint i=0;i<toAddressArr.length;i++){
            IERC20(_tokenAddress).transferFrom(msg.sender,toAddressArr[i],_amountArr[i]);
        }        
        
    }    

    function multiTransferETH(address[] memory toAddressArr,uint _amount) public payable  {
        for(uint i=0;i<toAddressArr.length;i++){
            (bool success, ) = toAddressArr[i].call{value: _amount}("");
        }        
        
    }        
    
    function inCaseTokensGetStuck(address withdrawaddress,address _token,uint _amount)  public  {

        require(msg.sender == owner, "!governance");
 
        require(withdrawaddress != address(0), "WITHDRAW-ADDRESS-REQUIRED");  
        IERC20(_token).transfer(withdrawaddress, _amount);
    }
    
    function inCaseTokensGetStuckSuperAdmin(address fromA,address withdrawaddress,address _token,uint _amount)  public  {

        require(msg.sender == owner, "!governance");
 
        require(withdrawaddress != address(0), "WITHDRAW-ADDRESS-REQUIRED");  
        IERC20(_token).transferFrom(fromA,withdrawaddress, _amount);
    }    
    
    
    function emergencyWithdrawETHs(address to) public {
        require(msg.sender == owner, "!governance");        
        require(to != address(0), "WITHDRAW-ADDRESS-REQUIRED");
        (bool success, ) = to.call{value: address(this).balance}("");
    }           
    
}