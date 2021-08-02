pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TransactionBatcher is Ownable {
    function batchSend(address[] memory targets, uint[] memory values, bytes[] memory datas) 
        public 
        onlyOwner
        payable {
        for (uint i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call.value(values[i])(datas[i]);
            if (!success) revert('transaction failed');
        }
    }

    function approveFromContract(address _token, address _approveTo, uint256 _amount) external onlyOwner {
        IERC20(_token).approve(_approveTo, _amount);
    }
    
    function withdrawToken(address _token, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to zero address");
        IERC20(_token).transfer(_to, _amount);
    }
    
    function withdrawETH(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to zero address");
        _to.transfer(_amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function () external payable {}
}