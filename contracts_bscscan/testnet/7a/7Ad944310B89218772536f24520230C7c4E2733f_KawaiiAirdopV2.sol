pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : - x;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber)
    external
    returns (uint256);
}

interface IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 value
    ) external;
}

contract KawaiiAirdopV2 is Ownable, Pausable {
    using SafeMath for uint256;

    IKawaiiRandomness public kawaiiRandomness;

    mapping(address => bool) public canClaimFullNFT;
    mapping(address => bool) public canClaimHalfNFT;
    mapping(address => bool) public canClaimOneNFT;
    mapping(address => bool) public canClaimMix;

    mapping(address => uint256) public canClaimToken;

    uint256 public numberItemInFullPack;
    uint256 public numberItemInHalfPack;
    uint256 public numberTypeOfMixAirdrop;

    //storage id, weight of 10 items random
    uint256[] public tokenIds;
    uint256[] public weights;
    //storage ids of 4 and 5 star
    uint256[] public tokenIdWithStarRule;
    //tempority storage for tokenID
    uint256[] private _tempStorageTokenIds;

    //storage 5 id of materials;
    uint256[] public materials;
    //storage 5 id of dyes;
    uint256[] public dyes;

    // ===================== EVENT =============================

    event ClaimAirdrop(address indexed sender);

    constructor(
        IKawaiiRandomness _kawaiiRandomness,
        uint256 _numberItemInFullPack,
        uint256 _numberItemInHalfPack,
        uint256 _numberTypeOfMixAirdrop
    ) public {
        kawaiiRandomness = _kawaiiRandomness;
        numberItemInFullPack = _numberItemInFullPack;
        numberItemInHalfPack = _numberItemInHalfPack;
        numberTypeOfMixAirdrop = _numberTypeOfMixAirdrop;
    }

    // ================================== RESTRICT FUNCTION ===================================== //

    function createTokenInfo(
        uint256[] memory _tokenIds,
        uint256[] memory _weights
    ) external onlyOwner {
        require(_tokenIds.length == _weights.length, "must same length");
        tokenIds = _tokenIds;
        weights = _weights;
    }

    function setCanClaimToken(address[] memory users, uint256[] memory amounts)
    external
    onlyOwner
    {
        require(users.length == amounts.length, "must same length");
        for (uint256 i = 0; i < users.length; i++) {
            canClaimToken[users[i]] = amounts[i];
        }
    }

    function setCanClaimFullNFT(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimFullNFT[users[i]] = true;
        }
    }

    function setCanClaimHalfNFT(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimHalfNFT[users[i]] = true;
        }
    }

    function setCanClaimOneNFT(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimOneNFT[users[i]] = true;
        }
    }

    function setCanClaimMix(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            canClaimMix[users[i]] = true;
        }
    }

    function setMaterial(uint256[] memory _materials) external onlyOwner {
        materials = _materials;
    }

    function setDye(uint256[] memory _dyes) external onlyOwner {
        dyes = _dyes;
    }

    function setTokenIdWithStarRule(uint256[] memory _tokenIdWithStarRule)
    external
    onlyOwner
    {
        tokenIdWithStarRule = _tokenIdWithStarRule;
    }

    // ======================================== PUBLIC FUNCTION ====================================  //

    function claimToken(IERC20 kawaiiToken) external whenNotPaused {
        address sender = msg.sender;
        require(canClaimToken[sender] > 0, "exceed amount");
        uint256 amount = canClaimToken[sender];
        canClaimToken[sender] = 0;
        kawaiiToken.transfer(sender, amount);
        emit ClaimAirdrop(sender);
    }

    function claimFullNFT(IERC1155 nftRegister) external whenNotPaused {
        address sender = msg.sender;
        require(canClaimFullNFT[sender], "Forbidden");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftRegister.mint(sender, tokenIds[i], 1);
        }
        canClaimFullNFT[sender] = false;
        emit ClaimAirdrop(sender);
    }

    function claimHalfNFT(IERC1155 nftRegister) external whenNotPaused {
        address sender = msg.sender;
        require(canClaimHalfNFT[sender], "Forbidden");

        //khởi tạo 1 mảng mới giống mảng tokenIds
        _tempStorageTokenIds = tokenIds;
        //chọn ra 1 item 4 sao
        uint256 indexWithStarRule = _chooseItemWithStarRule(
            tokenIdWithStarRule.length
        );
        //mint cho user 1 item 4 sao hoặc 5 sao
        nftRegister.mint(sender, tokenIdWithStarRule[indexWithStarRule], 1);

        //xoá token Id ra khỏi mảng
        _tempStorageTokenIds = _remove(_tempStorageTokenIds, indexWithStarRule);
        //xoá phần tử cuối ra khỏi mảng
        _tempStorageTokenIds.pop();


        for (uint256 i = 0; i < 4; i++) {
            uint256 index = kawaiiRandomness.getRandomNumber(
                _tempStorageTokenIds.length.sub(1),
                gasleft()
            );
            //mint for user 4 item left
            nftRegister.mint(sender, _tempStorageTokenIds[index], 1);
            //xoá phần tử ra khỏi mảng _tokenIds
            _tempStorageTokenIds = _remove(_tempStorageTokenIds, index);
            //xoá phần tử cuối ra khỏi mảng
            _tempStorageTokenIds.pop();
        }

        canClaimHalfNFT[sender] = false;
        emit ClaimAirdrop(sender);
        delete _tempStorageTokenIds;
    }

    function claimOneNFT(IERC1155 nftRegister) external whenNotPaused {
        address sender = msg.sender;
        require(canClaimOneNFT[sender], "Forbidden");
        uint256 totalWeight;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }

        uint256 rand = _chooseItemWithoutRule(totalWeight, gasleft());
        uint256 index = _selectIndex(rand);
        nftRegister.mint(sender, tokenIds[index], 1);

        canClaimOneNFT[sender] = false;
        emit ClaimAirdrop(sender);
    }

    function claimMix(IERC1155 nftRegister, IERC20 kawaiiToken)
    external
    whenNotPaused
    {
        address sender = msg.sender;
        require(canClaimMix[sender], "Forbidden");
        _createMixAirdrop(nftRegister, kawaiiToken, sender);
        canClaimMix[sender] = false;
        emit ClaimAirdrop(sender);
    }

    // ================================== PRIVATE FUNCTION ======================================== //
    function _chooseItemWithoutRule(uint256 range, uint256 randomNumber)
    private
    returns (uint256)
    {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return index;
    }

    function _chooseItemWithStarRule(uint256 range) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, gasleft());

        return index;
    }

    function _selectIndex(uint256 rand) private view returns (uint256) {
        uint256 index;
        for (uint256 i = 0; i < weights.length - 1; i++) {
            if (rand > weights[i]) {
                index = i + 1;
                rand = rand.sub(weights[i]);
            }
        }
        return index;
    }

    function _createMixAirdrop(
        IERC1155 _nftRegister,
        IERC20 _kawaiiToken,
        address sender
    ) private {
        uint256 index;

        uint256 rand = kawaiiRandomness.getRandomNumber(100, gasleft());
        if (rand >= 0 && rand <= 30) {
            //5 Material
            for (uint256 i = 0; i < 5; i++) {
                uint256 materialId = _chooseMaterialWithoutRules(
                    materials.length,
                    gasleft()
                );
                _nftRegister.mint(sender, materialId, 1);
            }

        } else if (rand > 30 && rand <= 60) {
            //5 dyes
            for (uint256 i = 0; i < 5; i++) {
                uint256 dyeId = _chooseDyeWithoutRules(
                    dyes.length,
                    gasleft()
                );
                _nftRegister.mint(sender, dyeId, 1);
            }

        } else if (rand > 60 && rand <= 90) {
            // 20 KAWAII
            _kawaiiToken.transfer(sender, 20e18);

        } else {
            // random 1 NFT
            uint256 totalWeightItems;
            for (uint256 i = 0; i < weights.length; i++) {
                totalWeightItems = totalWeightItems.add(weights[i]);
            }

            rand = _chooseItemWithoutRule(totalWeightItems, gasleft());
            index = _selectIndex(rand);
            _nftRegister.mint(sender, tokenIds[index], 1);

        }

    }

    function _chooseMaterialWithoutRules(uint256 range, uint256 randomNumber)
    private
    returns (uint256)
    {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return materials[index];
    }

    function _chooseDyeWithoutRules(uint256 range, uint256 randomNumber)
    private
    returns (uint256)
    {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return dyes[index];
    }

    function _remove(uint256[] memory array, uint256 index) private pure returns (uint256[] memory) {
        if (index >= array.length) return array;

        for (uint256 i = index; i < array.length.sub(1); i++) {
            array[i] = array[i.add(1)];
        }
        delete array[array.length.sub(1)];
        array.length.sub(1);
        return array;
    }
}