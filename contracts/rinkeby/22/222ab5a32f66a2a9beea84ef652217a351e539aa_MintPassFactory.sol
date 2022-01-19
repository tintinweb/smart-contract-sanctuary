// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./AbstractMintPassFactory.sol";
import "./PaymentSplitter.sol";


contract MintPassFactory is AbstractMintPassFactory, PaymentSplitter  {
    uint private mpCounter = 1; 
    uint private bCounter = 1; 
  
    // new mint passes can be added to support future collections
    mapping(uint256 => MintPass) public MintPasses;
    mapping(uint256 => Bundle) public Bundles;

    // 4 different whitelists; high to low priority
    mapping(address => Listed) public Whitelist;

    // sale state 
    // 0=closed; 1=notorious, 2=legendary, 3=og, 4=epic, 5=public
    uint8 public saleState = 0;
    uint8 public promoClaims = 60;
    uint8 public claimMax = 3;

    // members of whitelist
    struct Listed {
        uint8 quantity; // how many bundles minted
        uint8 priority; //1=notorious, 2=legendary, 3=og, 4=epic, 5=public
    }

    struct MintPass {
        uint256 quantity;
        string name;
        address redeemableContract; // contract of the redeemable NFT
        string uri;
    }

    struct Bundle {
        uint256 price;
        uint256 quantity;
        string name;
    }    

    constructor(
        string memory _name, 
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _paymentShares
    ) ERC1155("https://crtest.co/") PaymentSplitter(_payees, _paymentShares) {
        name_ = _name;
        symbol_ = _symbol;
        // add the bundles
        addBundle(.2112 ether, 7060, "LOW");
        addBundle(.5 ether, 3000, "MID");
        addBundle(3 ether, 500, "HIGH");
        // add the MP
        addMintPass(10560, "Cryptorunner", msg.sender, "https://crtest.co/tokens/1.json");
        addMintPass(7060, "Low Tier Land", msg.sender, "https://crtest.co/tokens/2.json");
        addMintPass(3000, "Mid Tier Land", msg.sender, "https://crtest.co/tokens/3.json");
        addMintPass(500, "High Tier Land", msg.sender, "https://crtest.co/tokens/4.json");
        addMintPass(7060, "Low Tier Item", msg.sender, "https://crtest.co/tokens/5.json");
        addMintPass(3000, "Mid Tier Item", msg.sender, "https://crtest.co/tokens/6.json");
        addMintPass(500, "High Tier Item", msg.sender, "https://crtest.co/tokens/7.json");

    } 

    function addMintPass(
        uint256  _quantity, 
        string memory _name,
        address _redeemableContract,
        string memory _uri

    ) public onlyOwner {

        MintPass storage mp = MintPasses[mpCounter];
        mp.quantity = _quantity;
        mp.redeemableContract = _redeemableContract;
        mp.name = _name;
        mp.uri = _uri;
        mpCounter += 1;
    }

    function editMintPass(
        uint256 _quantity, 
        string memory _name,        
        address _redeemableContract, 
        uint256 _mpIndex,
        string memory _uri
    ) external onlyOwner {

        MintPasses[_mpIndex].quantity = _quantity;    
        MintPasses[_mpIndex].name = _name;    
        MintPasses[_mpIndex].redeemableContract = _redeemableContract;  
        MintPasses[_mpIndex].uri = _uri;    
    }     


    function addBundle (
        uint256 _bundlePrice,
        uint256 _bundleQty,
        string memory _name
    ) public onlyOwner {
        require(_bundlePrice > 0, "addBundle: bundle price must be greater than 0");
        require(_bundleQty > 0, "addBundle: bundle quantity must be greater than 0");

        Bundle storage b = Bundles[bCounter];
        b.price = _bundlePrice;
        b.quantity = _bundleQty;
        b.name = _name;

        bCounter += 1;
    }

    function editBundle (
        uint256 _bundlePrice,
        uint256 _bundleQty,
        string memory _name,
        uint256 _bundleIndex
    ) external onlyOwner {
        require(_bundlePrice > 0, "editBundle: bundle price must be greater than 0");
        require(_bundleQty > 0, "editBundle: bundle quantity must be greater than 0");

        Bundles[_bundleIndex].price = _bundlePrice;
        Bundles[_bundleIndex].quantity = _bundleQty;
        Bundles[_bundleIndex].name = _name;
    }

    function burnFromRedeem(
        address account, 
        uint256[] calldata ids, 
        uint256[] calldata amounts
    ) external {
        for (uint i = 0; i < ids.length; i++) {
            require(MintPasses[ids[i]].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        }
        _burnBatch(account, ids, amounts);
    }  

    // mint a pass
    function claim(
        // list of quantities for each bundle
        // all three quantities must be submitted in the order of the bundles
        // eg. [0,2,1] mean bundle1 has 0, bundle2 has 2, bundle3 has 1
        uint8[] calldata _quantities 
    ) external payable {
        // verify contract is not paused
        require(saleState > 0, "Claim: claiming is paused");
        // Verify minting price
        require(msg.value >= 
            (Bundles[1].price * _quantities[0])
            + (Bundles[2].price * _quantities[1])
            + (Bundles[3].price * _quantities[2])
            , "Claim: Insufficient ether submitted.");

        // Verify quantity is within remaining available 
        require(Bundles[1].quantity - _quantities[0] >= 0, "Claim: Not enough bundle1 quantity");
        require(Bundles[2].quantity - _quantities[1] >= 0, "Claim: Not enough bundle2 quantity");
        require(Bundles[3].quantity - _quantities[2] >= 0, "Claim: Not enough bundle3 quantity");

        // Verify on whitelist if not public sale
        // warning: Whitelist[msg.sender].variable will return 0 if not on whitelist
        if (saleState < 5 ){
            require(
                Whitelist[msg.sender].priority >= 1  &&
                saleState >= Whitelist[msg.sender].priority &&
                Whitelist[msg.sender].quantity 
                    + _quantities[0] +  _quantities[1] + _quantities[2]
                    <= claimMax
            
                , "Claim: Not on whitelist or max claimed."
            );
            Whitelist[msg.sender].quantity = Whitelist[msg.sender].quantity + _quantities[0] +  _quantities[1] + _quantities[2];
        }
        
     // ok, mint
        uint256[] memory qtys = new uint256[](7);
        qtys[0] = 0;
        qtys[1] = 0;
        qtys[2] = 0;
        qtys[3] = 0;
        qtys[4] = 0;
        qtys[5] = 0;
        qtys[6] = 0;

        // bundle1 gets MPs 1,2,5
        if (_quantities[0] > 0) {
            qtys[0] = qtys[0] + _quantities[0];
            qtys[1] = qtys[1] + _quantities[0];
            qtys[4] = qtys[4] + _quantities[0];
            Bundles[1].quantity = Bundles[1].quantity - _quantities[0];
        }
        // bundle2 gets MPs 1, 3, 6
        if (_quantities[1] > 0) {
            qtys[0] = qtys[0] + _quantities[1];
            qtys[2] = qtys[2] + _quantities[1];
            qtys[5] = qtys[5] + _quantities[1];
            Bundles[2].quantity = Bundles[2].quantity - _quantities[1];
        }

        // bundle3 gets MPS 1, 4, 7
        if (_quantities[2] > 0) {
            qtys[0] = qtys[0] + _quantities[2];
            qtys[3] = qtys[3] + _quantities[2];
            qtys[6] = qtys[6] + _quantities[2];
            Bundles[3].quantity = Bundles[3].quantity - _quantities[2];
        }
        uint256[] memory ids = new uint256[](7);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        ids[3] = 4;
        ids[4] = 5;
        ids[5] = 6;
        ids[6] = 7;
        _mintBatch(msg.sender, ids, qtys, "");

    }

    // owner can send up to 60 promo bundle1
    function promoClaim(address _to, uint8 _quantity) external onlyOwner {
        require(promoClaims - _quantity >= 0, "Quantity exceeds available promos remaining. ");
        Bundles[1].quantity -= _quantity;
        promoClaims -= _quantity;
        // one cryptorunner, one low land, one low item
        uint256[] memory y = new uint256[](3);
        y[0] = 1;
        y[1] = 2;
        y[2] = 5;
        uint256[] memory x = new uint256[](3);
        x[0] = _quantity;
        x[1] = _quantity;
        x[2] = _quantity;
        //_safeBatchTransferFrom(address(this), _to, y, x, "");
        _mintBatch(_to, y, x, "");
    }

    // owner can update sale state
    function updateSaleStatus(uint8 _saleState) external onlyOwner {
        require(_saleState <= 5, "updateSaleStatus: saleState must be between 0 and 5");
        saleState = _saleState;
    }

    function updateClaimMax(uint8 _claimMax) external onlyOwner {
        require(_claimMax >= 0, "claimMax: claimMax must be greater than, or equal to 0");
        claimMax = _claimMax;
    }

    // add to whitelist
    function whitelistAddress(address[] calldata _add, uint8 _priority) public onlyOwner {
        for (uint i = 0; i < _add.length; i++) {
            //require(Whitelist[_add[i]].priority == 0 , "whitelistAddress: address already on whitelist");

            Listed storage l = Whitelist[_add[i]];
            l.priority = _priority;
            l.quantity = 0;
        }
    }

    // remove from whitelist
    function removeWhitelistAdress(address[] calldata _addr) public onlyOwner {
        for (uint i = 0; i < _addr.length; i++) {
            delete Whitelist[_addr[i]];
        }
    }

    // how many redemptions for address on Whitelist
    function getClaimedMps(address _address) public view returns (uint256) {
        return Whitelist[_address].quantity;
    }

    // token uri
    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(MintPasses[_id].uri);
    }    
}