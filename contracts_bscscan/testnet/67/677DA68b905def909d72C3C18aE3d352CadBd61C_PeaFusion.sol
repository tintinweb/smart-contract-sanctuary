// SPDX-License-Identifier: UNLICENSED
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IPeaRouter.sol";
import "./IPeaNFT.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

contract PeaFusion is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum FusionClass {
        ECONOMY, //10_000 + 0%
        STANDARD, //20_000 + 10%
        PREMIUM, //40_000 + 30%
        PROFESSIONAL, //70_000 + 40%
        VIP, //100_000 + 50%
        VVIP //200_000 +80%
    }

    enum FusionResult {
        FAILED,
        SUCCESS
    }

    struct FusionSession {
        uint256 tokenId;
        uint256 foodId;
        FusionResult result;
        uint256 time;
    }

    event FusionEvent(uint256 indexed tokenId, uint256 indexed foodId, address user, FusionResult result);

    uint256[8] private seeds;
    uint256 private seeders;
    bytes32 private seedKey;

    mapping(uint256 => uint256[]) public fusionSessionsTime;
    mapping(address => FusionSession[]) public fusionSessions;

    bool public paused;
    
    IPeaRouter public peaRouter;
    IERC20 public peaToken;
    IPeaNFT public peaNFT;

    constructor(address _peaRouter, IERC20 _peaToken, address _peaNFT) {
        peaRouter = IPeaRouter(_peaRouter);
        peaToken = _peaToken;
        peaNFT = IPeaNFT(_peaNFT);
        generateRandom();
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function fusion(uint256 _mainTokenId, uint256 _foodTokenId, FusionClass _fClass) external {
        require(!paused, "Not fusion season");
        require(peaNFT.ownerOf(_mainTokenId) == _msgSender(), "not own");
        require(peaNFT.ownerOf(_foodTokenId) == _msgSender(), "not own");

        if (Address.isContract(_msgSender()) || _msgSender() != tx.origin) {
            revert("not accept here");
        }
        
        IPeaNFT.Pean memory _main_pean = peaNFT.getPean(_mainTokenId);
        IPeaNFT.Pean memory _food_pean = peaNFT.getPean(_foodTokenId);

        require(uint8(_main_pean.champ) > 0, "Can not fusion a Gem");
        require(uint8(_main_pean.champ) < 5, "Champ already max level");

        require(_food_pean.champ == _main_pean.champ, "Food have to same Champ");
        require(_food_pean.level == _main_pean.level, "Food have to same Level");

        peaNFT.transferFrom(address(msg.sender), address(this), _mainTokenId);
        peaNFT.transferFrom(address(msg.sender), address(this), _foodTokenId);

        uint256 fusionFee = getFee(_fClass);
        peaToken.transferFrom(_msgSender(), peaRouter.feeAddress(), fusionFee);
        
        uint256 rnd = getRandom(_mainTokenId.add(block.number % 100).mul(_foodTokenId), 4).div(100);
        uint256 sucRate = getSuccessRate(uint256(_main_pean.level), uint256(_fClass), rnd.div(10));

        FusionResult _res = FusionResult.FAILED;
        if (rnd < sucRate) {
            _res = FusionResult.SUCCESS;
            _main_pean.level = IPeaNFT.Level(uint8(uint256(_main_pean.level) + 1));
        }

        fusionSessionsTime[_mainTokenId].push(block.timestamp);

        fusionSessions[_msgSender()].push(
            FusionSession({
                tokenId: _mainTokenId,
                foodId: _foodTokenId,
                result: _res,
                time: block.timestamp
            })
        );

        generateRandom();

        peaNFT.transferFrom(address(this), address(msg.sender), _mainTokenId);
        peaNFT.transferFrom(address(this), address(0), _foodTokenId);

        emit FusionEvent(_mainTokenId, _foodTokenId, _msgSender(), _res);
    }

    function getFee(FusionClass _fusionClass)
        private
        pure
        returns (uint256)
    {
        uint8 _fClass = uint8(_fusionClass);
        return _fClass == 0 ? 10 * 10**3 * 10**18
            : (_fClass == 1 ? 20 * 10**3 * 10**18
            : (_fClass == 2 ? 40 * 10**3 * 10**18
            : (_fClass == 3 ? 70 * 10**3 * 10**18
            : (_fClass == 4 ? 100 * 10**3 * 10**18
            : (_fClass == 5 ? 200 * 10**3  * 10**18 : 10 * 10**3 * 10**18
            )))));
    }

    function getSuccessRate(uint256 _level, uint256 _fClass, uint256 winRateRnd)
        private
        pure
        returns (uint256)
    {
        uint256 _classRate = _fClass == 0 ? 0
                          : (_fClass == 1 ? 10
                          : (_fClass == 2 ? 20
                          : (_fClass == 3 ? 40
                          : (_fClass == 4 ? 50
                          : (_fClass == 5 ? 80 : 0
                          )))));

        uint256 _lvRate = _level == 0 ? 79
                       : (_level == 1 ? 69
                       : (_level == 2 ? 49
                       : (_level == 3 ? 39
                       : (_level == 4 ? 9 : 0
                       ))));

        return winRateRnd.add(_lvRate).add(_classRate);
    }

    function generateRandom() public {
        seeders++;
        for (uint256 index = 0; index < 8; index++) {
            bytes32 _bytes32 = keccak256(
                abi.encodePacked(
                    block.timestamp - (index + seeders),
                    index + seeders
                )
            );
            seeds[index] = _random(uint256(_bytes32), 8);
        }
    }

    function getRandom(uint256 _any, uint256 _length)
        internal
        view
        returns (uint256)
    {
        uint256 index = uint8(
            _random(uint256(keccak256(abi.encode(_any, seedKey))), _length)
        );
        while (index >= 8) {
            index /= 2;
        }
        return
            _random(
                uint256(keccak256(abi.encode(seeds[index], seedKey))),
                _length
            );
    }

    function _random(uint256 _id, uint256 _length)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        (block.timestamp - block.number),
                        _id,
                        _length,
                        uint256(keccak256(abi.encodePacked(block.coinbase))),
                        (uint256(keccak256(abi.encodePacked(msg.sender))))
                    )
                )
            ) % (10**_length);
    }

    function setManager(address _config) public onlyOwner {
        peaRouter = IPeaRouter(_config);
    }

    function setNFT(address _peaNFT) public onlyOwner {
        peaNFT = IPeaNFT(_peaNFT);
    }

    function setERC20(address _peaToken) public onlyOwner {
        peaToken = IERC20(_peaToken);
    }
}