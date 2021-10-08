//SourceUnit: TronsuranceTronconomyV1.sol

pragma solidity 0.8.6;


interface TronconomyPaymentPool {
    function adminDeposit() external payable returns(bool);
    function totalBalance() external view returns(uint256);
}


contract TronsuranceTronconomyV1 {
    bool private admin1Approved;
    bool private admin2Approved;
    address private admin1;
    address private admin2;
    TronconomyPaymentPool public pool = TronconomyPaymentPool(0x536D94E429695182C13dB49A30f8C12ad0990E1b);

    event Admin1Transferred(address indexed previousAdmin1, address indexed newAdmin1);
    event Admin2Transferred(address indexed previousAdmin2, address indexed newAdmin2);

    constructor () public {
        admin1Approved = false;
        admin2Approved = false;
        admin1 = msg.sender;
        admin2 = address(0x0A921Fe71251421d343A16c865616Ec4B04F71F0);
        emit Admin1Transferred(address(0), admin1);
        emit Admin2Transferred(address(0), admin2);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin1 || msg.sender == admin2, "Caller is not admin");
        _;
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin is the zero address");

        if (msg.sender == admin1) {
            require(newAdmin != admin2, "New admin already is admin2");
            emit Admin1Transferred(admin1, newAdmin);
            admin1 = newAdmin;
            admin1Approved = false;
        } else if (msg.sender == admin2) {
            require(newAdmin != admin1, "New admin already is admin1");
            emit Admin2Transferred(admin2, newAdmin);
            admin2 = newAdmin;
            admin2Approved = false;
        }
    }

    function transferBalanceToPool() public onlyAdmin {
        require(address(this).balance > 0, "Insurance balance too low");
        uint256 poolBalance = pool.totalBalance();
        require(poolBalance < 5000000000000, "Pool balance too high");

        if (msg.sender == admin1 && !admin1Approved) {
            admin1Approved = true;
        }

        if (msg.sender == admin2 && !admin2Approved) {
            admin2Approved = true;
        }

        if (admin1Approved && admin2Approved) {
            bool sent = pool.adminDeposit{value: address(this).balance}();
            require(sent, "Transfer failed");

            admin1Approved = false;
            admin2Approved = false;
        }
    }

    function emergencyWithdraw(address _to) payable public onlyAdmin {
        require(_to != address(0), "Target is the zero address");
        require(address(this).balance > 0, "Balance too low");
        (bool sent,) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    // Function to receive TRX, msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}