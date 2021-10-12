// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./StringUpper.sol";
import "./DenyList.sol";

contract NameTag is ERC721, Ownable, StringUpper, DenyList {

    using SafeMath for uint256;

    struct Wave {
        uint256 limit;
        uint256 startTime;
    }

    Wave[] waves;

    //    from 0 to 4
    uint8 private _currentWaveIndex = 0;

    mapping(uint256 => string) tokenNames;
    mapping(string => uint256) names;

    string private _defaultMetadata;
    string private _defaultNamedMetadata;

    uint8 private _tokenAmountBuyLimit;
    uint256 private _price;
    uint256 private _metadataFee;
    address private _metadataRole;
    mapping(uint256 => string) private _tokenURIs;

    event NameChanged(uint256 indexed tokenId, string from, string to);

    constructor(string memory name_, string memory symbol_, uint256 price_, uint256 metadataFee_, uint8 tokenAmountBuyLimit_) ERC721(name_, symbol_) {
        _price = price_;
        _metadataFee = metadataFee_;
        _tokenAmountBuyLimit = tokenAmountBuyLimit_;

        _metadataRole = msg.sender;

        waves.push(Wave(2500, 0));
        waves.push(Wave(5000, 0));
        waves.push(Wave(7500, 0));
        waves.push(Wave(10000, 0));
        waves.push(Wave(type(uint256).max, 0));
    }

    function currentWaveIndex() public view virtual returns (uint8) {
        return _currentWaveIndex;
    }

    function currentLimit() public view virtual returns (uint256) {
        return waves[_currentWaveIndex].limit;
    }

    function currentWave() public view virtual returns (uint256, uint256) {
        return (waves[_currentWaveIndex].limit, waves[_currentWaveIndex].startTime);
    }

    function waveByIndex(uint8 waveIndex_) public view virtual returns (uint256, uint256) {
        require(waveIndex_ >= 0 && waveIndex_ < waves.length);
        return (waves[waveIndex_].limit, waves[waveIndex_].startTime);
    }

    function price() public view virtual returns (uint256) {
        return _price;
    }

    function metadataFee() public view virtual returns (uint256) {
        return _metadataFee;
    }

    function defaultMetadata() public view virtual returns (string memory) {
        return _defaultMetadata;
    }

    function defaultNamedMetadata() public view virtual returns (string memory) {
        return _defaultNamedMetadata;
    }

    function tokenAmountBuyLimit() public view virtual returns (uint8) {
        return _tokenAmountBuyLimit;
    }

    function metadataRole() public view virtual returns (address) {
        return _metadataRole;
    }

    function changeMetadataRole(address newAddress) public virtual onlyOwner {
        require(newAddress != address(0));
        _metadataRole = newAddress;
    }

    function setWaveStartTime(uint8 waveIndex_, uint256 startTime_) public virtual onlyOwner {
        require(waveIndex_ >= 0 && waveIndex_ < waves.length);

        require(startTime_ != 0);
        require(block.timestamp <= startTime_);

        uint256 time = waves[waveIndex_].startTime;
        require(time == 0 || time > block.timestamp);
        waves[waveIndex_].startTime = startTime_;
    }

    function setPrice(uint256 price_) public virtual onlyOwner {
        require(price_ > 0);
        _price = price_;
    }

    function setMetadataFee(uint256 metadataFee_) public virtual onlyOwner {
        require(metadataFee_ >= 0);
        _metadataFee = metadataFee_;
    }

    function setDefaultMetadata(string memory metadata_) public virtual onlyOwner {
        _defaultMetadata = metadata_;
    }

    function setDefaultNamedMetadata(string memory metadata_) public virtual onlyOwner {
        _defaultNamedMetadata = metadata_;
    }

    function setTokenAmountBuyLimit(uint8 tokenAmountBuyLimit_) public virtual onlyOwner {
        require(tokenAmountBuyLimit_ > 0);
        _tokenAmountBuyLimit = tokenAmountBuyLimit_;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }

    // deny 1 words
    function addDenyList(string[] memory _words) public override onlyOwner {
        super.addDenyList(_words);
    }

    function removeDenyList(string[] memory _words) public override onlyOwner {
        super.removeDenyList(_words);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override virtual {
        require(_exists(tokenId), "NT: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _preValidatePurchase() internal view {
        uint256 time = waves[currentWaveIndex()].startTime;
        require(time != 0 && block.timestamp >= time, "NT: Current wave has not started yet");
        require(msg.sender != address(0));
        require(msg.value >= price(), "NT: Insufficient funds");
    }

    function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
        if (currentWaveIndex() < waves.length - 1) {
            uint256 amount = _weiAmount.div(price());
            uint256 toNextLimitAmount = currentLimit().sub(totalSupply());

            if (amount >= toNextLimitAmount) {
                _currentWaveIndex += 1;
                return toNextLimitAmount;
            }
            return amount;
        }

        return _weiAmount.div(price());
    }

    function _processPurchaseToken(address recipient) internal returns (uint256) {
        uint256 newItemId = totalSupply().add(1);
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function validate(string memory name) internal pure returns (bool, string memory) {
        // name chữ hoa hoặc thường, có số, không có 2 dấu cách liền nhau
        // return chuyển thành chữ hoa hết
        bytes memory b = bytes(name);
        if (b.length == 0) return (false, '');
        if (b.length > 36) return (false, '');

        bytes memory bUpperName = new bytes(b.length);

        bool prevSpace = false;
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (char == 0x20) { //(space)
                if (i == 0 || i == b.length - 1 || prevSpace) {
                    return (false, '');
                }

                prevSpace = true;
            } else {
                if (
                    !(char >= 0x30 && char <= 0x39) && //9-0
                    !(char >= 0x41 && char <= 0x5A) && //A-Z
                    !(char >= 0x61 && char <= 0x7A) //a-z
                ) {
                    return (false, '');
                }
                prevSpace = false;
            }
            bUpperName[i] = _upper(char);
        }

        return (true, string(bUpperName));
    }

    function _setName(uint256 _token, string memory _name) internal returns (bool) {
        require(msg.sender != address(0));

        if (msg.sender != ownerOf(_token)) {
            return false;
        }

        return _changeTokenName(_token, _name);
    }

    function setNames(uint256[] memory _tokens, string[] memory _names) public payable returns (bool[] memory) {
        require(_tokens.length == _names.length);

        uint256 weiAmount = msg.value;
        bool[] memory statuses = new bool[](_tokens.length);
        bool fullStatus = false;
        for (uint index = 0; index < _tokens.length; index += 1) {
            bool hasName = bytes(getTokenName(_tokens[index])).length > 0;
            statuses[index] = _setName(_tokens[index], _names[index]);

            if (hasName && statuses[index]) {
                require(weiAmount >= metadataFee(), "NT: Insufficient fee funds");
                weiAmount -= metadataFee();

                _setTokenURI(_tokens[index], '');
            }

            if (!fullStatus && statuses[index]) {
                fullStatus = statuses[index];
            }
        }

        require(fullStatus); // at least one name was set

        return statuses;
    }

    function setMetadata(uint256 _token, string memory _metadata) public {
        require(msg.sender == metadataRole());
        _setTokenURI(_token, _metadata);
    }

    function setMetadataList(uint256[] memory _tokens, string[] memory _metadata) public {
        require(msg.sender == metadataRole());

        require(_tokens.length == _metadata.length);
        for (uint index = 0; index < _tokens.length; index += 1) {
            _setTokenURI(_tokens[index], _metadata[index]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NT: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        if (bytes(getTokenName(tokenId)).length > 0) {
            return string(abi.encodePacked(base, defaultNamedMetadata()));
        }
        return string(abi.encodePacked(base, defaultMetadata()));
    }

    function getByName(string memory name) public view virtual returns (uint256) {
        return names[upper(name)];
    }

    function getTokenName(uint256 tokenId) public view virtual returns (string memory) {
        return tokenNames[tokenId];
    }

    function _changeTokenName(uint256 tokenId, string memory _name) internal virtual returns(bool){
        require(_exists(tokenId), "NT: Name set of nonexistent token");

        bool status;
        string memory upperName;
        (status, upperName) = validate(_name);
        if (status == false || names[upperName] != 0 || denyList[upperName]) {
            return false;
        }

        string memory oldName = getTokenName(tokenId);
        string memory oldUpperName = upper(oldName);
        names[oldUpperName] = 0;
        tokenNames[tokenId] = _name;
        names[upperName] = tokenId;

        emit NameChanged(tokenId, oldName, _name);
        return true;
    }

    function _buyTokens() internal returns(uint256) {
        _preValidatePurchase();
        uint256 tokensAmount = _getTokenAmount(msg.value);
        require(tokensAmount <= tokenAmountBuyLimit(), "NT: Limited amount of tokens");
        return tokensAmount;
    }

    function buyNamedTokens(string[] memory _names) external payable returns (uint256[] memory) {
        uint256 tokensAmount = _buyTokens();

        uint256[] memory tokens = new uint256[](tokensAmount);

        for (uint index = 0; index < tokensAmount; index += 1) {
            tokens[index] = _processPurchaseToken(msg.sender);

            if (index < _names.length) {
                require(_setName(tokens[index], _names[index]), "NT: Name cannot be assigned");
            }
        }

        return tokens;
    }

    function buyTokens() external payable returns (uint256[] memory) {
        uint256 tokensAmount = _buyTokens();

        uint256[] memory tokens = new uint256[](tokensAmount);

        for (uint index = 0; index < tokensAmount; index += 1) {
            tokens[index] = _processPurchaseToken(msg.sender);
        }

        return tokens;
    }

    function buyNamedToken(string memory _name) external payable returns (uint256) {
        _preValidatePurchase();

        uint256 token = _processPurchaseToken(msg.sender);
        require(_setName(token, _name), "NT: Name cannot be assigned");
        return token;
    }

    function buyToken() external payable returns (uint256) {
        _preValidatePurchase();

        return _processPurchaseToken(msg.sender);
    }
}