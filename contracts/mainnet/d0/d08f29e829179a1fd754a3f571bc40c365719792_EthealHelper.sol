pragma solidity ^0.4.21;

contract iWhitelist {
    mapping(address => bool) public isWhitelisted;
}

contract iDeposit {
    struct Deposit {
        uint256 amount;         // 32 byte
        address beneficiary;    // 20 byte
        uint64 time;            // 8 byte
        bool cleared;           // 1 bit
    }
    uint256 public transactionCount;
    mapping (uint256 => Deposit) public transactions;
    iWhitelist public whitelist;
}

/**
 * @title EthealHelper
 * @author thesved, viktor.tabori at etheal.com
 * @notice Helper to forward transactions
 */
contract EthealHelper {
    function getTx(address _deposit, uint256 i) view public returns (uint256 amount, address beneficiary, uint64 time, bool cleared) {
        return iDeposit(_deposit).transactions(i);
    }
    
    function forwardable(address _deposit) view external returns (uint256[] ids) {
        iDeposit deposit = iDeposit(_deposit);
        uint256 _a = 0;
        address _b = 0x0;
        uint256 _t = 0;
        bool _c = false;
        uint256 i = 0;
        uint256 results = 0;
        uint256 txs = deposit.transactionCount();
        uint256[] memory _ids = new uint256[](txs);

        // search in contributors
        for (i = 0; i < txs; i++) {
            (_a, _b, _t, _c) = getTx(_deposit, i);
            if (!_c && deposit.whitelist().isWhitelisted(_b)) {
                _ids[results] = i;
                results++;
            }
        }

        ids = new uint256[](results);
        for (i = 0; i < results; i++) {
            ids[i] = _ids[i];
        }

        return ids;
    }
}