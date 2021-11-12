/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/interface/MinterMintable.sol

pragma solidity ^0.8.7;

interface MinterMintable {
    function isMinter(address check) external view returns (bool);
    function mint(address owner) external returns (uint256);
    function batchMint(address owner, uint256 amount) external returns (uint256[] memory);
}

// File: contracts/WhitelistedPresale.sol

pragma solidity ^0.8.7;



contract WhitelistedPresale is Ownable {

    MinterMintable _minterMintable_;

    constructor(address ghettoSharkhoodAddress) {
        _minterMintable_ = MinterMintable(ghettoSharkhoodAddress);
        
        /**
         * Here are pre-added addresses
         */
        setBuyerCap(0x3EE4b6E2DCD43E5Ee301C44736aCf79436a431B6, 35);
        setBuyerCap(0x0A39035007cCf9f973ac5338bc44195A137064C3, 110);
        setBuyerCap(0x18E72F42452FE218D885075833DB4Fe201Ab248A, 120);
        setBuyerCap(0x82bF281F8C78998929500f7047ff9EbA160bcB11, 15);
        setBuyerCap(0x7c09D3f88f9F38ca085bA30aC98Bb9ac5Edb39fa, 35);
        setBuyerCap(0x96C7eb488DA4cafD53B88eE9d344B3805cB67e79, 120);
        setBuyerCap(0x3c42BEc4D334d04f91f528C0FE1B54DD3dd61bdb, 2);
        setBuyerCap(0x9C74F1a06CEa6587029029f3dE875D08757B9960, 2);
        setBuyerCap(0x7B3ea3001cbfB19fe7142757811056680C062114, 5);
        setBuyerCap(0x10c1c5554d4ed417D1d3b0E9c7B08e057bC9Cb3c, 3);
        setBuyerCap(0xC36261bD4FAC1B7C76645d54656848d22a4F11b6, 3);
        setBuyerCap(0xFfE4261a55f4d5AE916D1130Ce4D9132f9Adb262, 20);
        setBuyerCap(0x2d19EB511f34778073a487c87902ee631C59Bbc1, 4);
        setBuyerCap(0x6957535bEE8DCCEBC66daCd443B4438939D3da7C, 3);
        setBuyerCap(0x406E4e822E0706Acf2c958d00ff82452020c556B, 3);
        setBuyerCap(0xB536Ffe4BBa83a1E776bE71364b0D62aC8A9F2de, 5);
        setBuyerCap(0x60d3fC0E271d3DA94a8fa9Df1185b1a39B1CB30F, 3);
        setBuyerCap(0xb2ECA6156c7625a9d2b9BBAC8c6EC9AE4aFC3556, 2);
        setBuyerCap(0xFB34ae3A0b2b794C8ec6750A7716E0570bA05e86, 2);
        setBuyerCap(0xC84F8d68D5822acE53D817D6FBF7191B37729698, 6);
        setBuyerCap(0x224E8D327A186709E1B7D5733a654a7CF08AefA7, 1);
        setBuyerCap(0xE2a55d478866Ec60A4549950820390f4Bf5CAfB9, 10);
        setBuyerCap(0x4c00aaAe552De7476122687b05589c25D61312Df, 2);
        setBuyerCap(0x713b8C9f2713a07a43EDA78B454BEaB9D9E96015, 3);
        setBuyerCap(0x4C41389089E20c884085d0940EE8fFd97e946Bf0, 3);
        setBuyerCap(0x87481D0816D92d15540FA526919Dd2b9Bd07Aa8D, 3);
        setBuyerCap(0x2574510F644B91E20bA15d027Ec0519A5706458e, 3);
        setBuyerCap(0x1020f21C49F97588C4582b0E31399E0649C07844, 10);
        setBuyerCap(0xc52aBE15B7C4126401F6B451cF482837372D06F5, 3);
        setBuyerCap(0x8418A464f0f51C958D1b57A5fb88D1A9896E8232, 6);
        setBuyerCap(0x2a32093A20D9E1D3f0620FbA008c9b2107Aa0D39, 3);
        setBuyerCap(0x308292aD5Be57Ec7A1425bb9393c6e53b7547639, 2);
        setBuyerCap(0xa713fe75BCeA20Dd04aBae00205F0706806693ae, 2);
        setBuyerCap(0xB2d8d1FD49091c34aF63913B6bb88464dE99e932, 3);
        setBuyerCap(0xab04e55702C16dfF1D435AB3ac063c7044403A15, 3);
        setBuyerCap(0x7254bb676d9cB54281028c4083455e85e2904C1b, 4);
        setBuyerCap(0xE611f1fC579564d192cA238273bEE50F0cFd921d, 4);
        setBuyerCap(0x26dE28DB4d04a1ACbCF349c8bd047552d7ef65E9, 3);
        setBuyerCap(0xa1356800cA03CEAf074D811d3158079ce71aE0b6, 10);
        setBuyerCap(0xBcbE7E9a54b0FB501A91D7065d539B3efAA11522, 3);
        setBuyerCap(0xaB1a170Ec67AA0F2279eA2B0cc80a09D18aBc86D, 3);
        setBuyerCap(0x665CbA347bbA2DE7444C20eb3EDee6fFEaB353aD, 3);
        setBuyerCap(0x1DF2C79d6c521710A444F3291aDeA9Ca594DcFeB, 4);
        setBuyerCap(0xb5ee4F2681042395517aA4DaA00c9474c803F858, 3);
        setBuyerCap(0x4F46613946Ed215E1CCfeA0C65b4aD4A700a7747, 2);
        setBuyerCap(0x54e748Fed11c67642E330cC64249A4dE663859B3, 2);
        setBuyerCap(0x571E89bd70D4D5141dC15c45153a86a146c9a098, 2);
        setBuyerCap(0xE8C07Ea73AC5cD60e1c098A8ac369d01234a0B14, 2);
        setBuyerCap(0x76Ea289C8Dc50446eA604b89cBBFAF6086fd38A6, 2);
        setBuyerCap(0xe47D6169B6db5F63775D222c25e204feE3Ffa6cc, 2);
        setBuyerCap(0xdf0460CBd0D1219785b07F1e19bE8A07d7a0db8c, 2);
        setBuyerCap(0x5CD334C41Cd8da95Be22D44DE617FeD9ce12363A, 2);
        setBuyerCap(0x10eEA07f522633557a4eB00bff16C2f466D49983, 3);
        setBuyerCap(0xdF370Df571f3D5099ccAf0B236cAA08e4Fe47C44, 10);
        setBuyerCap(0x21A6560EF9510DC3d16E61fF71D8D9C69ba86876, 3);
        setBuyerCap(0x184b8165e747817551EaC977cF93D7dD4cBE18c4, 3);
        setBuyerCap(0x2622A9d55d687E96C6320f64AD8c323ccD3B1115, 2);
        setBuyerCap(0xa7315FB43541C2CA6788135746B26D10f73fFe63, 3);
        setBuyerCap(0x2837707F05013Eb5bF1C02B8A20B76A7b48B1C1e, 2);
        setBuyerCap(0xbE74308B06E7361dDCE50F5C27732CfA4fEf4fEa, 2);
        setBuyerCap(0x40E5d921644e8DA11cBB41129F11963A60Aa8408, 3);
        setBuyerCap(0xe11D6fe5918820A53c7aB7C4c37183aB29A4b103, 3);
        setBuyerCap(0x326A525fB1A4D6210DD7c547840be38E9FCf61FF, 3);
        setBuyerCap(0x6D324cf6F977A2e22935B8b33dF33729Eb41f5aE, 5);
        setBuyerCap(0x938169BafD32092a7efF3EC6317B4597f8BD3feb, 3);
        setBuyerCap(0xC88Bd215AFe47fFFCEdc6C4127e797394e9dE3BE, 5);
        setBuyerCap(0x4DA33Cf3100E5DA72285F1Cc282cf056ce0ADD51, 2);
        setBuyerCap(0xB13a509B8E3Dd88f4a5239c1cC4a749111CCa5a7, 6);
        setBuyerCap(0xDBB004449f307199c6AfAF16A6121B2a3E5E41c1, 3);
        setBuyerCap(0xB147c8e797EfEC75deB4A90F4add0E10f08db0Ac, 1);
        setBuyerCap(0xFC3b39bB00Cf842067A6aD6Dd661DF70dB4c012e, 8);
        setBuyerCap(0xaB58f3dE07Fb3455D218438A99d69B3f06F23C49, 2);
        setBuyerCap(0x6Ca3cD0a63faa12ffA3FB2F1d269F74e8Cf26F9a, 1);
        setBuyerCap(0xBf7c5F30057288FC2D7D406B6F6c57E1D3235A27, 3);
        setBuyerCap(0x5444C883AA97d419AC20DCDbD7767F632b1A7669, 2);
        setBuyerCap(0x266af5d837c2C5A43b9272468683dEA751880857, 3);
        setBuyerCap(0x9a290AF64601F34debadc26526a1A52F7a554E1b, 2);
        setBuyerCap(0x1a7EdEcB2212fF27860325729f695E1F9020bA9C, 3);
        setBuyerCap(0x1066B2240E1Ed1ee49f8aFf6F0d6628663F00c73, 5);
        setBuyerCap(0x9DBE3CfC34867cfB988Af5ef8396BC6B08aFcbB8, 1);
        setBuyerCap(0x974c1CB84f439826c100b20063C24D72226Fd4A8, 4);
        setBuyerCap(0x69cFabF25bf4B629416BF589E27f37a8A8Fe0A34, 2);
        setBuyerCap(0x2a198F10FD12dA7d6C055c0fCB0cd055cAfA20Bc, 2);
        setBuyerCap(0x0aCCCE2ff34A11FE00AF55754DB34796b37aF668, 1);
        setBuyerCap(0x1074411b026a1B50c09eafFd99dF4D22D91B3B66, 5);
        setBuyerCap(0x63f390B96C48DDDB0F7E576DeFc032eA3f4572d8, 50);
        setBuyerCap(0x0D512DC652A77D960e1e1Aa01e96d17413AE3200, 2);
        setBuyerCap(0xA75Fb6444Bf3809FcBD5A33F91739c8c0B436caC, 100);
        setBuyerCap(0x8053843d83282e91f9DAaecfb66fE7C440545Ef8, 2);
        setBuyerCap(0x6E770Af4766510E70a459BB2438240A9136918d9, 1);
        setBuyerCap(0x184b8165e747817551EaC977cF93D7dD4cBE18c4, 3);
        setBuyerCap(0xfB01E26e2070A3C032CEb182cf6aa5Ece36010E8, 20);
        setBuyerCap(0x0F87cD8301a0B74CCa321Be2b3e92fF859dd59Cb, 2);
        setBuyerCap(0x365B92074BA2c7Ee93D387A0a34e674ac3930fE7, 20);
        setBuyerCap(0xCfDA32B2f94C5AEF74704f1FB8f135464e3264D3, 3);
        setBuyerCap(0x8F7688E9958708151c1f8d81641999B29e620d10, 2);
        setBuyerCap(0xa7315FB43541C2CA6788135746B26D10f73fFe63, 2);
    }

    uint256 _price_ = 0.069 ether;

    // Whitelist

    struct buyerData {
        uint256 cap; // the max number of NFT buyer can buy
        uint256 bought; // the number of NFT buyer have bought
    }

    mapping(address => buyerData) _buyers_;

    /**
     * This purpose of this function is to check whether buyer can buy,
     */
    modifier onlyAllowedBuyer(uint256 amount) {
        require(
            amount <= 10000 
            && _buyers_[msg.sender].bought + amount > _buyers_[msg.sender].bought
            && _buyers_[msg.sender].bought + amount <= _buyers_[msg.sender].cap, 
            "Presale: this address is not allowed to buy."
        );
        _;
    }

    /**
     * Set buyer cap, only owner can do this operation, and this function can be call before closing.
     */
    function setBuyerCap(address buyer, uint256 cap) public onlyOwner onlyOpened {
        _buyers_[buyer].cap = cap;
    }

    /**
     * This function can help owner to add larger than one addresses cap.
     */
    function setBuyerCapBatch(address[] memory buyers, uint256[] memory amount) public onlyOwner onlyOpened {
        require(buyers.length == amount.length, "Presale: buyers length and amount length not match");
        require(buyers.length <= 100, "Presale: the max size of batch is 100.");
        
        for(uint256 i = 0; i < buyers.length; i ++) {
            _buyers_[buyers[i]].cap = amount[i];
        }
    }

    function buyerCap(address buyer) public view returns (uint256) {
        return _buyers_[buyer].cap;
    }

    function buyerBought(address buyer) public view returns (uint256) {
        return _buyers_[buyer].bought;
    }

    // withdraw related functions

    function withdraw() public onlyOwner {
        address payable receiver = payable(owner());
        receiver.transfer(address(this).balance);
    }

    // open and start control

    bool _opened_ = true;
    bool _started_ = false;

    modifier onlyOpened() {
        require(_opened_, "Presale: presale has been closed.");
        _;
    }
    
    modifier onlyDuringPresale() {
        require(_started_, "Presale: presale is not now.");
        _;
    }

    function start() public onlyOwner onlyOpened {
        _started_ = true;
    }

    function end() public onlyOwner onlyOpened {
        _started_ = false;
    }

    function close() public onlyOwner onlyOpened {
        _started_ = false;
        _opened_ = false;
    }

    function started() public view returns (bool) {
        return _started_;
    }

    function opened() public view returns (bool) {
        return _opened_;
    }

    // Presale

    uint256 _sold_ = 0;

    /**
     * Only pay larger than or equal to total price will
     */
    modifier onlyPayEnoughEth(uint256 amount) {
        require(msg.value >= amount * _price_, "Presale: please pay enough ETH to buy.");
        _;
    }

    /**
     * Buy one NFT in one transaction
     */
    function buy() public payable 
        onlyOpened
        onlyDuringPresale 
        onlyAllowedBuyer(1) 
        onlyPayEnoughEth(1)
        returns (uint256) {
        _sold_ += 1;
        _buyers_[msg.sender].bought += 1;
        return _minterMintable_.mint(msg.sender);
    }

    /**
     * Buy numbers of NFT in one transaction.
     * It will also increase the number of NFT buyer has bought.
     */
    function buyBatch(uint256 amount) public payable 
        onlyOpened
        onlyDuringPresale 
        onlyAllowedBuyer(amount) 
        onlyPayEnoughEth(amount)
        returns (uint256[] memory) {
        require(amount >= 1, "Presale: batch size should larger than 0.");
        _sold_ += amount;
        _buyers_[msg.sender].bought += amount;
        return _minterMintable_.batchMint(msg.sender, amount);
    }

    /**
     * Get the number of NFT has been sold during presale
     */
    function sold() public view returns (uint256) {
        return _sold_;
    }

}