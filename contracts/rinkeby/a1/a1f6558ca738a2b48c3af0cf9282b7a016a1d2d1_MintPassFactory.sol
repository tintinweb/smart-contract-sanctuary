// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./AbstractMintPassFactory.sol";
import "./PaymentSplitter.sol";


contract MintPassFactory is AbstractMintPassFactory, PaymentSplitter  {
    uint private mpCounter = 1; 
    uint private bCounter = 1; 
  
    // new mint passes can be added to support future collections
    mapping(uint256 => MintPass) public mintPasses;
    mapping(uint256 => Bundle) public Bundles;

    // 4 different whitelists; high to low priority
    mapping(address => Listed) public Whitelist;

    // sale state 
    // 0=closed; 1=notorious, 2=legendary, 3=og, 4=epic, 5=public
    uint8 public saleState = 0;
    uint8 public promoClaims = 60;
    uint8 public claimMax = 3;
    
    event Claimed(uint index, address indexed account, uint amount);

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

        MintPass storage mp = mintPasses[mpCounter];
        mp.quantity = _quantity;
        mp.name = _name;
        mp.redeemableContract = _redeemableContract;
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

        mintPasses[_mpIndex].quantity = _quantity;    
        mintPasses[_mpIndex].name = _name;    
        mintPasses[_mpIndex].redeemableContract = _redeemableContract;  
        mintPasses[_mpIndex].uri = _uri;    
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
        uint256 mpIndex, 
        uint256 amount
    ) external {
        require(mintPasses[mpIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        // to do batchburn
        _burn(account, mpIndex, amount);
    }  

    // mint a pass
    function claim(
        uint8 _bundleId,
        uint8 _quantity
    ) external payable {
        // verify contract is not paused
        require(saleState > 0, "Claim: claiming is paused");
        // Verify minting price
        require(msg.value >= Bundles[_bundleId].price * _quantity
            , "Claim: Ether value incorrect");

        // Verify quantity is within remaining available 
        require(Bundles[_bundleId].quantity - _quantity >= 0, "Claim: Not enough bundle quantity");

        // Verify whitelist
        require(
                (
                    saleState >= Whitelist[msg.sender].priority &&
                    Whitelist[msg.sender].quantity + _quantity <= claimMax
                )
                || 
            ( 
                saleState == 5
            )
            , "Claim: Not on whitelist or max claimed."
        );

        // return over payment
        uint256 excessPayment = msg.value - (_quantity * (Bundles[_bundleId].price));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        

        // ok, mint
        Whitelist[msg.sender].quantity = Whitelist[msg.sender].quantity + _quantity;
        Bundles[_bundleId].quantity = Bundles[_bundleId].quantity - _quantity;
        uint256[] memory x = new uint256[](3);
        x[0] = _quantity;
        x[1] = _quantity;
        x[2] = _quantity;
        uint256[] memory y = new uint256[](3);
        y[0] = 1;
        if (_bundleId == 1) {
            // one cryptorunner, one low land, one low item
            y[1] = 2;
            y[2] = 5;
            _mintBatch(msg.sender, y, x, "");
        } else if (_bundleId == 2) {
            // mid bundle: one cryptorunner, one mid land, one mid item
            y[1] = 3;
            y[2] = 6;
            _mintBatch(msg.sender, y, x, "");
        } else if (_bundleId == 3) {
            // high bundle: one cryptorunner, one high land, one high item
            y[1] = 4;            
            y[2] = 7;
            _mintBatch(msg.sender, y, x, "");
        }
        
        emit Claimed(_bundleId, msg.sender, _quantity);
    }

    // owner can send up to 60 promo bundle1
    function promoClaim(address _to, uint8 _quantity) external onlyOwner {
        require(promoClaims - _quantity >= 0, "Quantity exceeds available promos remaining. ");
        Bundles[1].quantity = Bundles[1].quantity - _quantity;
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
        _mintBatch(_to, y, x, "");
        emit Claimed(1, _to, _quantity);
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
            require(Whitelist[_add[i]].priority == 0 , "whitelistAddress: address already on whitelist");

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
            
            return string(mintPasses[_id].uri);
    }    
}