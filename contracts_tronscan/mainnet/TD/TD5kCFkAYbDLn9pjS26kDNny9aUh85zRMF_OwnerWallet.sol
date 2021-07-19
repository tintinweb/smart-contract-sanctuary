//SourceUnit: OwnerWallet.sol

pragma solidity 0.5.9;

interface ITGO {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function numHolders() external view returns (uint256);
    function holders(uint256 _index) external view returns (address payable);
}

interface ITRONGO {
    function payoutShare() external;
}

contract OwnerWallet {
    address owner;
    Contract public TGO_CONTRACT;
    Contract public TRONGO_CONTRACT;
    Contract public ACCELERATOR_CONTRACT;
    uint256 public sharingUnit = 100000000000; // 1000 TGO
    bool processing;

    struct Contract {
        bool initialized;
        address payable addr;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Permission denied');
        _;
    }

    // Constructor
    constructor() public {
        owner = msg.sender;
        TGO_CONTRACT.initialized = false;
        TRONGO_CONTRACT.initialized = false;
        ACCELERATOR_CONTRACT.initialized = false;
    }

    function () payable external {
        // Do nothing
    }

    function setTokenAddress(address payable _addr) external onlyOwner returns (bool) {
        require(!TGO_CONTRACT.initialized, 'Already initialized');
        TGO_CONTRACT = Contract(true, _addr);
        return true;
    }

    function setTronGoContract(address payable _addr) external onlyOwner returns (bool) {
        require(!TRONGO_CONTRACT.initialized, 'Already initialized');
        TRONGO_CONTRACT = Contract(true, _addr);
        return true;
    }

    function setAcceleratorContract(address payable _addr) external onlyOwner returns (bool) {
        ACCELERATOR_CONTRACT = Contract(true, _addr);
        return true;
    }

    function payoutShare() external {
        // Re-entrancy protection
        if(!processing) {
            processing = true;

            ITRONGO trongo = ITRONGO(TRONGO_CONTRACT.addr);
            trongo.payoutShare();

            uint256 tgoShare = address(this).balance / 2;
            uint256 totalUnit;

            ITGO token = ITGO(TGO_CONTRACT.addr);
            for(uint i = 0; i < token.numHolders(); i++) {
                if(token.holders(i) != TRONGO_CONTRACT.addr) {
                    uint256 unit = token.balanceOf(token.holders(i)) / sharingUnit;
                    if(unit > 0) {
                        totalUnit += unit;
                    }
                }
            }

            for(uint i = 0; i < token.numHolders(); i++) {
                if(token.holders(i) != TRONGO_CONTRACT.addr) {
                    uint256 unit = token.balanceOf(token.holders(i)) / sharingUnit;
                    if(unit > 0) {
                        uint256 share = (tgoShare * unit) / totalUnit;
                        token.holders(i).transfer(share);
                    }
                }
            }

            // Payout to TGX Accelerator
            uint256 tgxShare = address(this).balance;
            ACCELERATOR_CONTRACT.addr.transfer(tgxShare);

            // Process completed
            processing = false;
        }
    }

    function resetProcessing() external onlyOwner returns (bool) {
        processing = false;
    }
}