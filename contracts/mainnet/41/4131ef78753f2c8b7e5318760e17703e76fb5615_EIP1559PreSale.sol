/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT


// File: Context.sol



pragma solidity ^0.6.2;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: Ownable.sol

pragma solidity ^0.6.2;




contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: IERC20.sol



pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: Presale.sol



pragma solidity ^0.6.2;



contract EIP1559PreSale is Ownable {
    
    uint256 private _hardCap = 30 * 1e18;
    IERC20 private _rewardToken = IERC20(0x76c99738d6946093204dbec97ed8D80BADA6cA52);
    uint256 private _contributionSize = 3 * 1e17;
    
    uint256 public contributionRecieved;
    bool public _openForAll;
    mapping (address => bool) private _whitelist;
    mapping (address => bool) public _contributed;
    mapping (address => uint256) public _claimed;
    
    constructor () public {
        setWhitelist(0xBd07c941bcFD93e6315863FA453cd8a5673128F5, true);
        setWhitelist(0x68091B72Fbd74A499c863c4d9DcF5460Aac182F1, true);
        setWhitelist(0xF12D505b8C73EA71E8Fe92598f20B59a86b1644e, true);
        setWhitelist(0x2e08188f39c946b4a9d0B6C91a6A89d6fBC52949, true);
        setWhitelist(0x9Ffb857E3AF210950c17a546988a5D8c5ce01Fd6, true);
        setWhitelist(0xa816706a0D62Dacf1814E024F8BBEd22460B1101, true);
        setWhitelist(0x501C9501EbCa4B060E380D925D9c3492EABCD9e6, true);
        setWhitelist(0xa2dFab4a289633E8D0c48db1F5f0481953f93318, true);
        setWhitelist(0xA053DbaFbA05E307a7BdDedE09C7FEB235dC34b1, true);
        setWhitelist(0xe18228b19A67c4F5f68Bea30892b248EfAe3156A, true);
        setWhitelist(0xDab8F8F5a20A3A280eAABaF34533eE6CdD269135, true);
        setWhitelist(0xbCb5DC467D09d518a0EBa0bd968A3ecfB37768C8, true);
        setWhitelist(0x0A0871c2Ea6f24149758Dc5bd1136D337b7F47b8, true);
        setWhitelist(0x494E35c0A11dc16a109fc161d785385F874F2359, true);
        setWhitelist(0x97389e30d5Da915B21ACD29b2b94A725e60c3C6A, true);
        setWhitelist(0xEe32d08E674dBC7ED9547f02E39DA62a4689e7B5, true);
        setWhitelist(0xD1288DeDE59A193A6D4aD25644aDBb4607b03597, true);
        setWhitelist(0xd3c5F881EB6941821855Ae2ec0237c99423F0f95, true);
        setWhitelist(0x4bC4Ad70A89eBECFa5DDBE87F914edD4Bc153BC8, true);
        setWhitelist(0x8ef3c04470BEFa5aD8386233ea911173C9eA6c83, true);
        setWhitelist(0x6efA29B2D4A989669D79F5fEceb582e58BBaA27D, true);
        setWhitelist(0xd98811DbAEbc23f7B52035ffF155Bb531E1542D0, true);
        setWhitelist(0xc85dD4d0eBFbA5f0dE0b052FF224FAFDa18F617b, true);
        setWhitelist(0x9f1E064DD0DeA444dF264D7B8EA51b697D39DD57, true);
        setWhitelist(0x059236F121b5721cfbf3c56e9C49c3A0a7b45AcF, true);
        setWhitelist(0xda3d024626AeB843F84Df6887c076413835744eC, true);
        setWhitelist(0x4146bF6509A74eD4E06FB705910339fD5633312F, true);
        setWhitelist(0x62BF18a26fE430D7c0D7B166f07E430d354E0475, true);
        setWhitelist(0x5c50b8f75E7E6BCa7Ea0529acE284787512E1608, true);
        setWhitelist(0x04b936745C02E8Cb75cC68b93B4fb99b38939d5D, true);
        setWhitelist(0xEcBC379d48820F9DB52e95a43CB2E54d43e9410C, true);
        setWhitelist(0xa262A26d0516023bd8085fDfAE3F1160c9d2A25f, true);
        setWhitelist(0xae717CD01a52Af7cBe10048e08cfa275c44FA144, true);
        setWhitelist(0xFD81ce7688104A9F1251860145f51959d579c220, true);
        setWhitelist(0x0BdeA9EBec344Cb37D90Bf119FdbB957628Fec43, true);
        setWhitelist(0x61C98F7110DdcE29680CD7EB6E1cd77a81D7587A, true);
        setWhitelist(0x0095B77ceB0178AAa38DC14a13C95a902d021BED, true);
        setWhitelist(0xFB9deb5b6C488Fe61e1A8A482c5cEF1A583321d2, true);
        setWhitelist(0x9a81E05BB4bd25Df6297dF5768C6E7E66EEa62BD, true);
        setWhitelist(0x399b282c17F8ed9F542C2376917947d6B79E2Cc6, true);
        setWhitelist(0x483846f18E7662445575FFd4186660aF80834C5B, true);
        setWhitelist(0xF22b04a4443A4f7A4967644156b8E2de8df38844, true);
        setWhitelist(0xFE932efB9dbB8E563E95CEe05ce106509cF06905, true);
        setWhitelist(0xb45024C28F3eA8288293D4633de0898F62271E5E, true);
        setWhitelist(0xe163Ae0126BDB01C0A84E4e80fE14CF5EFFeb1E6, true);
        setWhitelist(0x18ee0e786A69049C09758058aD527d3483665270, true);
        setWhitelist(0xEb9e1109f5f9ca3a5E5c4a8B0C6E9Aa0aF7945D0, true);
        setWhitelist(0xDC5F24b36a31d9A84837C7329A82EB0078953D16, true);
        setWhitelist(0x1E8566BBF137c8A0339e8A4DF0951228da77b929, true);
        setWhitelist(0x1e5A689F9D4524Ff6f604cDA19c01FAa4cA664eA, true);
        setWhitelist(0xFED8bE3943215df9dDa3F052eB7aBb9600959aEB, true);
        setWhitelist(0x4B424674eA391E5Ee53925DBAbD73027D06699A9, true);
        setWhitelist(0x66979BF23C37Ada615642db9148919136E18955E, true);
        setWhitelist(0x0f30a0710FC4f881e7F0D8cABC39Ac879F7E7E02, true);
        setWhitelist(0x4553eD5d8d3731E629f67BD86abd021175F31848, true);
        setWhitelist(0x56bfC207B3CFEea6402a56CF8cecA0Fe9f04B2F9, true);
        setWhitelist(0x58c344A1745917dC321803201D5B73db99058566, true);
        setWhitelist(0x76773870d3374fC2f85eee569cCef6b2167339fC, true);
        setWhitelist(0xf3815489b70C0A3a0B626f183B1f1240F63E06a6, true);
        setWhitelist(0xc855631CF2b5a78C28Dc7121dA549C06E5334B66, true);
        setWhitelist(0x77444A92c8294d40a097DF15A12E62Bb4BFA820C, true);
        setWhitelist(0x70465066513848D031bFD6E46B11192797Bed47c, true);
        setWhitelist(0x497E3561f6D87b6E81f46b121879217D4457D1a1, true);
        setWhitelist(0xCE8ff5Fa965dAf4C864f45a5A5af3Fe24AFC034D, true);
        setWhitelist(0x9a40709D61A82B3e382B9BB6944F4213d01937CD, true);
        setWhitelist(0xdCfDf94d278Bf8f54a289D3E658524850a8Be840, true);
        setWhitelist(0x66E8Eb5800C055745281700F2986417F312121ed, true);
        setWhitelist(0xb7726fc620576263d8840649Df057366201487ae, true);
        setWhitelist(0x91A41fC7653F57584d46475Db4936deB032D35A0, true);
        setWhitelist(0xe53717Ea0F8121b3E65A21ec7eCbF436385108B9, true);
        setWhitelist(0x057deFc3756FFF4be88A87073954f6E3b1B560fe, true);
        setWhitelist(0xB534C33C7200869AEF3B467c7f94b84feEA382b3, true);
        setWhitelist(0xa1f8eEc7140c671fc58Bd03a2B48EbCD85ee3ba3, true);
        setWhitelist(0xef65A754240B8E1AC45F2A7407dE61188B4A6776, true);
        setWhitelist(0x5a31cb0A9b819Cf50d46CDE979863E5920349FF4, true);
        setWhitelist(0x90cfC0E17855C195FB307c16680d511469C483D4, true);
        setWhitelist(0xd8Fa4fc7E2F905d85bDB4d0A9a69156c2D58ED11, true);
        setWhitelist(0xb02160d146901E838F9e9E796296ece30c129e0A, true);
        setWhitelist(0xFa1FCccB68941E9111d4d9F8af6c739dd062BA5b, true);
        setWhitelist(0x2f095d00d0cFF2cB759Db1F3a59Dd12a08181109, true);
        setWhitelist(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274, true);
        setWhitelist(0x7bEA73fAabEDfFe8f012fb8438eD55de8E4181A3, true);
        setWhitelist(0xfBA6faE38594561A85e8F741AB31a0A2e59E4b5b, true);
        setWhitelist(0x1ad432c5EA2Ed5CAD93EeF708c9C26762529d251, true);
        setWhitelist(0x54dFAbC7f3C268a287fC8e4c94dC3F7e73F4E39F, true);
        setWhitelist(0xA7eC3E91Dbf47D9DFb39d2a747592300A8F38881, true);
        setWhitelist(0xac7A4089ae970B141Bb215effC6d42E2A14Ee6DF, true);
        setWhitelist(0x8695D430353B4b4DC37f4b78f40ca83282bbF5AC, true);
        setWhitelist(0x447B45eb1e8Abd737b934F1a53e5d0C9751E274e, true);
        setWhitelist(0xB997db6a43D408c43BD5FbF4EB05C5e3ce8c65eb, true);
        setWhitelist(0x521A2689B6eAd8477f1097143e1c54089DCBe2Ce, true);
        setWhitelist(0x289Ba1EB9580D9c81Ed9448f99196f5D141911A7, true);
        setWhitelist(0x74Ed2223F082DBba8a653388671c394dA0B6f10E, true);
        setWhitelist(0x70B20209c83ec8D01e3c7F2ec77BDe7c40cDF2F6, true);
        setWhitelist(0xAF723bD11f32316bAeC9d0bf33cD3927Ff5135B5, true);
        setWhitelist(0xC7DA5D83322e85CEdA9D7681dcde52e001428D5D, true);
        setWhitelist(0x8147545d128CB58FF8fca6AA9CFd6ed2f984BCD1, true);
        setWhitelist(0x11AfA1b198ffb09F46067e5ce72CE0531429097E, true);
        setWhitelist(0x497E3561f6D87b6E81f46b121879217D4457D1a1, true);
        setWhitelist(0x782196F072cA65FB05B3Ae35b67Eb2637d31E29A, true);
    }
    


    function setWhitelist(address user, bool enabled) public onlyOwner {
        _whitelist[user] = enabled;
    }

    function toggleOpenForAll() public onlyOwner {
        _openForAll = !_openForAll;
    }

    function emergencyWithdrawTokens() public onlyOwner {
        _rewardToken.transfer(owner(), _rewardToken.balanceOf(address(this)));
    }
    
    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        contribute();
  	}
    
    function contribute() public payable {
        require(contributionRecieved< _hardCap, "PreSale is filled.");
        if (!_openForAll){
            require(_whitelist[msg.sender], "User not Whitelisted.");
        }
        require(msg.value >= _contributionSize, "Contribution amount too low.");
        require(!_contributed[msg.sender], "Already contributed.");
        if (msg.value > _contributionSize){
            msg.sender.transfer(msg.value - _contributionSize);
        }
        _contributed[msg.sender] = true;
        contributionRecieved += _contributionSize;
    }

    function claimable(address user) public view returns (uint256){
        require(_contributed[user], "No contribution provided.");
        uint256 claimable_ = 0;
        if (block.timestamp > 1628699400) {
            claimable_ += 666502*1e18;
        }
        if (block.timestamp > 1628785800) {
            claimable_ += 611166*1e18;
        }
        if (block.timestamp > 1628872200) {
            claimable_ += 611166*1e18;
        }
        if (block.timestamp > 1628958600) {
            claimable_ += 611166*1e18;
        }

        claimable_ = claimable_ - _claimed[user];
        return claimable_;
    }

    function claim() public {
        require(_contributed[msg.sender], "No contribution provided.");
        uint256 claimable_ = claimable(msg.sender);
        _claimed[msg.sender] += claimable_;
        if (claimable_ > 0) {
            _rewardToken.transfer(msg.sender, claimable_);
        }

    }


    
}