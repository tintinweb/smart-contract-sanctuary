/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "../utils/Context.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


//import "@openzeppelin/contracts/access/Ownable.sol";
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


//import "./Common/IManager.sol";
//-----------------------------------
// IManager
//-----------------------------------
interface IManager {
    //--------------------------------------
    // event
    //--------------------------------------
    event CoinCreated( uint256 indexed coinId, address indexed coinAddress );
    event Donated( uint256 indexed tokenId, uint256 indexed amount, uint256 indexed total );

    //--------------------------------------
    // 参照
    //--------------------------------------
    function getConfigAddress() external view returns (address);
    function getTotalDonated( uint256 coinId ) external view returns (uint256);

    //--------------------------------------    
    // NFTの発行
    //--------------------------------------
    function mintIdol( uint256 tokenId, uint256 rarity, string[] calldata attributes, address holder ) external;

    //--------------------------------------
    // NFTの操作
    //--------------------------------------
    function setIdolNmae( uint256 tokenId, string calldata name ) external;
    function setIdolDescription( uint256 tokenId, string calldata description ) external;
    function setIdolFolder( uint256 tokenId, string calldata folder ) external;
    function setIdolAvatar( uint256 tokenId, string calldata avatar ) external;
    function setIdolImage( uint256 tokenId, string calldata image ) external;
    function setIdolHtml( uint256 tokenId, string calldata html ) external;
    function addIdolAttribute( uint256 tokenId, string calldata attribute ) external;
    function removeIdolAttribute( uint256 tokenId, string calldata attribute ) external;

    //--------------------------------------
    // コインの発行
    //--------------------------------------
    function donate( uint256 tokenId, address from, uint256 amount ) external;

    //--------------------------------------
    // コインの操作
    //--------------------------------------
    function mintCoin( uint256 coinId, address to, uint256 amount ) external;
    function transferCoin( uint256 coinId, address from, address to, uint256 amount ) external;
    function burnCoin( uint256 coinId, address from, uint256 amount ) external;
}

//import "./Common/ICartridge.sol";
//-----------------------------------------------------------------------
// カートリッジ：インターフェイス
//-----------------------------------------------------------------------
interface ICartridge {
    //----------------------------------------
    // スカウトの確認
    //----------------------------------------
    function checkScout( address target ) external view returns (bool);

    //----------------------------------------
    // 残弾の取得
    //----------------------------------------
    function getRemaining() external view returns (uint256);

    //----------------------------------------
    // tokenIdの確認
    //----------------------------------------
    function checkTokenId( uint256 tokenId ) external pure returns (bool);

    //----------------------------------------
    // tokenIdの変換
    //----------------------------------------
    function convTokenId( uint256 tokenId ) external view returns (uint256);

    //----------------------------------------
    // データの取り出し
    //----------------------------------------
    function getDataAt( uint256 at ) external view returns (uint256);

    //----------------------------------------
    // データの消費
    //----------------------------------------
    function wasteAt( uint256 at ) external;
}


//import "./Common/LibRand.sol";
//--------------------------
// 乱数ライブラリ
//--------------------------
library LibRand {
    //----------------------------------------------------------------------------------------------------------------------
    // 乱数のシードの生成：[rand32]への初期値となる値を作成する
    //----------------------------------------------------------------------------------------------------------------------
    // [rand32]が繰り返し呼ばれる流れを複数実装する場合、[seed]値を変えることで、同じ[base]値から異なる初期値を取りだせる
    //（※例えば、[rand32]を複数呼ぶ関数をコールする際、同じ初期値を使ってしまうと関数の呼び先で同じ乱数が生成されることになるので注意すること）
    //----------------------------------------------------------------------------------------------------------------------
    function randInitial32WithBase( uint256 base, uint8 seed ) internal pure returns (uint32) {
        // ベース値から[32]ビット抽出する（※[seed]の値により取り出し位置を変える）
        // [seed]の値によってシフトされるビットは最大で[13*7+37=128]となる（※[uint160=address]の最上位32ビットまでを想定）
        return( uint32( base + seed + (base >> (13*(seed%8) + (seed%38))) ) );
    }

    //----------------------------------------------------------
    // 乱数の作成：[BASEFEE]を利用したなんちゃって乱数
    // [BASEFEE]はローカルでは動かないので注意（invalid opcodeが出る）
    //----------------------------------------------------------
    function createRand32( uint256 base0, uint8 seed ) internal view returns(uint32) {
        // base値の算出
        uint256 base1 = uint256( uint160(msg.sender) ); // addressを流用
        //uint256 base2 = block.basefee;                  // basefeeを流用
        uint256 base = (base0 ^ base1 /*^ base2*/);

        uint32 initial = randInitial32WithBase( base, seed );
        return( updateRand32( initial ) );
    }

    //----------------------------------------------------------
    // 乱数の更新：返値を次回の入力に使うことで乱数の生成を繰り返す想定
    //----------------------------------------------------------
    function updateRand32( uint32 val ) internal pure returns (uint32) {
        val ^= (val >> 13);
        val ^= (val << 17);
        val ^= (val << 15);

        return( val );
    }
}



//-----------------------------------
// Scout
//-----------------------------------
contract Scout is Ownable {
    //--------------------------------------
    // 定数
    //--------------------------------------
    // スカウトタイプ(レアリティ)
    uint256 constant private SCOUT_TYPE_COMMON = 0;
    uint256 constant private SCOUT_TYPE_RARE   = 1;
    uint256 constant private SCOUT_TYPE_ORIGIN = 2;
    uint256 constant private SCOUT_TYPE_MAX    = 3;

    // 属性
    uint256 constant private ATTRIBUTE_DATA_MAX = 8;
    string[] private ATTRIBUTES = [
        "Yandere",
        "Tsundere",
        "Tennnen",
        "Mischievous",
        "Sensei",
        "Nerd",
        "Trap",
        "Geek",
        "Moe Fag",
        "Big Sister",
        "Little Sister",
        "Nurturing Parent",
        "Nojaloli",
        "Elder",
        "Tender",
        "Senpai",
        "Kouhai",
        "Mischievous",
        "Aggressive",
        "Positive",
        "disgusting",
        "Cyborg",
        "isekai\u2019d",
        "Patient",
        "Optimistic",
        "approachable",
        "Psychic",
        "Magical",
        "Lady",
        "Lucky",
        "Unlucky",
        "Mysterious",
        "bad texter",
        "Shut in",
        "Arachnerd",
        "Shipper",
        "Emotionally unstable",
        "Sense of Justice"
    ];

    //--------------------------------------
    // 管理データ
    //--------------------------------------
    // マネージャ(処理を仲介できるアドレス)
    address private _manager;

    // 販売情報
    bool[SCOUT_TYPE_MAX] private _arrOnSale;
    uint256[SCOUT_TYPE_MAX] private _arrPriceRandom;
    uint256[SCOUT_TYPE_MAX] private _arrPriceDirect;
    uint256[SCOUT_TYPE_MAX] private _arrTotal;
    uint256[SCOUT_TYPE_MAX] private _arrMinted;
    ICartridge[][3] private _arrCartridges;

    //--------------------------------------
    // コンストラクタ
    //--------------------------------------
    constructor() Ownable() {
        /*
        _arrOnSale[SCOUT_TYPE_COMMON] = false;
        _arrOnSale[SCOUT_TYPE_RARE]   = false;
        _arrOnSale[SCOUT_TYPE_ORIGIN] = false;
        */

        _arrPriceRandom[SCOUT_TYPE_COMMON] = 40000000000000000000;      // 40 MATIC
        _arrPriceRandom[SCOUT_TYPE_RARE]   = 400000000000000000000;     // 400 MATIC
        _arrPriceRandom[SCOUT_TYPE_ORIGIN] = 4000000000000000000000;    // 4000 MATIC

        _arrPriceDirect[SCOUT_TYPE_COMMON] = 60000000000000000000;      // 60 MATIC
        _arrPriceDirect[SCOUT_TYPE_RARE]   = 600000000000000000000;     // 600 MATIC
        _arrPriceDirect[SCOUT_TYPE_ORIGIN] = 6000000000000000000000;    // 6000 MATIC

        /*
        _arrPriceRandom[SCOUT_TYPE_COMMON] = 4000000000000000;          // 0.004 MATIC
        _arrPriceRandom[SCOUT_TYPE_RARE]   = 40000000000000000;         // 0.04 MATIC
        _arrPriceRandom[SCOUT_TYPE_ORIGIN] = 400000000000000000;        // 0.4 MATIC

        _arrPriceDirect[SCOUT_TYPE_COMMON] = 6000000000000000;          // 0.006 MATIC
        _arrPriceDirect[SCOUT_TYPE_RARE]   = 60000000000000000;         // 0.06 MATIC
        _arrPriceDirect[SCOUT_TYPE_ORIGIN] = 600000000000000000;        // 0.6 MATIC
        */

        _arrTotal[SCOUT_TYPE_COMMON] = 8888;
        _arrTotal[SCOUT_TYPE_RARE]   = 1000;
        _arrTotal[SCOUT_TYPE_ORIGIN] = 100;

        /*
        _arrMinted[SCOUT_TYPE_COMMON] = 0;
        _arrMinted[SCOUT_TYPE_RARE]   = 0;
        _arrMinted[SCOUT_TYPE_ORIGIN] = 0;
        */

        _arrCartridges[SCOUT_TYPE_COMMON] = new ICartridge[](0);
        _arrCartridges[SCOUT_TYPE_RARE]   = new ICartridge[](0);
        _arrCartridges[SCOUT_TYPE_ORIGIN] = new ICartridge[](0);
    }

    //---------------------------------------
    // [external] マネージャ確認
    //---------------------------------------
    function manager() external view returns (address) {
        return( _manager );
    }

    //---------------------------------------
    // [external/onlyOwner] マネージャ設定
    //---------------------------------------
    function setManager( address __manager ) external onlyOwner {
        _manager = __manager;
    }

    //---------------------------------------
    // [external] 販売確認
    //---------------------------------------
    function checkOnSale( uint256 scoutType ) external view returns (bool) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        return( _arrOnSale[scoutType] );
    }

    function checkPriceRandom( uint256 scoutType ) external view returns (uint256) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        return( _arrPriceRandom[scoutType] );
    }

    function checkPriceDirect( uint256 scoutType ) external view returns (uint256) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        return( _arrPriceDirect[scoutType] );
    }

    function checkTotal( uint256 scoutType ) external view returns (uint256) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        return( _arrTotal[scoutType] );
    }

    function checkMinted( uint256 scoutType ) external view returns (uint256) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        return( _arrMinted[scoutType] );
    }

    function checkCartridgeAt( uint256 scoutType, uint256 at ) external view returns (address) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        require( at >= 0 && at < _arrCartridges[scoutType].length, "invalid at" );
        return( address(_arrCartridges[scoutType][at]) );
    }

    // 一括で取得
    function checkSaleInfo( uint256 scoutType ) external view returns (uint256[5] memory) {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );

        uint256[5] memory info;
        if( _arrOnSale[scoutType] ){
            info[0] = 1;
        }else{
            info[0] = 0;
        }
        info[1] = _arrPriceRandom[scoutType];
        info[2] = _arrPriceDirect[scoutType];
        info[3] = _arrTotal[scoutType];
        info[4] = _arrMinted[scoutType];

        return( info );
    }

    //---------------------------------------
    // [external/onlyOwner] 販売設定
    //---------------------------------------
    function setOnSale( uint256 scoutType, bool flag ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        _arrOnSale[scoutType] = flag;
    }

    function setPriceRandom( uint256 scoutType, uint256 price ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        _arrPriceRandom[scoutType] = price;
    }

    function setPriceDirect( uint256 scoutType, uint256 price ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        _arrPriceDirect[scoutType] = price;
    }

    function setTotal( uint256 scoutType, uint256 total ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        _arrTotal[scoutType] = total;
    }

    function setMinted( uint256 scoutType, uint256 minted ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );
        _arrMinted[scoutType] = minted;
    }

    function setCartridges( uint256 scoutType, address[] calldata arrAddress ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );

        uint256 total = 0;
        delete _arrCartridges[scoutType];
        for( uint256 i=0; i<arrAddress.length; i++ ){
            _arrCartridges[scoutType].push( ICartridge( arrAddress[i] ) );
            require( _arrCartridges[scoutType][i].checkScout( address(this) ), "invalid scout" );
            total += _arrCartridges[scoutType][i].getRemaining();
        }

        require( total == _arrTotal[scoutType], "invalid total" );
    }

    //---------------------------------------
    // [external] ランダムで候補の取得
    //---------------------------------------
    function getRandomMintableTokenId( uint256 scoutType, uint256 randAdd ) external view returns (uint256) {
        if( _arrTotal[scoutType] <= _arrMinted[scoutType] ){
            return( 0 );
        }
        uint256 remain = _arrTotal[scoutType] - _arrMinted[scoutType];

        // 抽選
        uint256 randBase = block.timestamp + remain;
        uint8 randSeed = uint8(block.number + randAdd);
        uint256 at = (LibRand.createRand32( randBase, randSeed )) % remain;

        // 対象のスロットの特定
        uint256 target = 0;
        for( uint256 j=0; j<_arrCartridges[scoutType].length; j++ ){
            uint256 temp = _arrCartridges[scoutType][j].getRemaining();
            if( temp > at ){
                target = j;
                break;
            }
            at -= temp;
        }

        // データの取得
        uint256 data = _arrCartridges[scoutType][target].getDataAt( at );

        // tokenId
        uint256 tokenId = (data & 0xffffffff00) >> 8;
        return( tokenId );
    }

    //---------------------------------------
    // [external/payable] NFTの発行(ランダム)
    //---------------------------------------
    function mintIdolRandom( uint256 scoutType ) external payable {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );

        // 販売中か？
        require( _arrOnSale[scoutType], "not on sale" );

        // 入金は有効か？
        require( _arrPriceRandom[scoutType] <= msg.value, "insufficient value" );

        // 残りはあるか？
        require( _arrMinted[scoutType] < _arrTotal[scoutType], "sold out"  );

        // 残り個数
        uint256 remain = _arrTotal[scoutType] - _arrMinted[scoutType];

        // 抽選
        uint256 randBase = block.timestamp + remain;
        uint8 randSeed = uint8(block.number);
        uint256 at = (LibRand.createRand32( randBase, randSeed )) % remain;

        // 対象のスロットの特定
        uint256 target = 0;
        for( uint256 j=0; j<_arrCartridges[scoutType].length; j++ ){
            uint256 temp = _arrCartridges[scoutType][j].getRemaining();
            if( temp > at ){
                target = j;
                break;
            }
            at -= temp;
        }

        // mint
        _mintIdol( scoutType, _arrCartridges[scoutType][target], at, msg.sender );
    }

    //---------------------------------------
    // [external/payable] NFTの発行（ID指定)
    //---------------------------------------
    function mintIdolDirect( uint256 scoutType, uint256 tokenId ) external payable {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );

        // 販売中か？
        require( _arrOnSale[scoutType], "not on sale" );

        // 入金は有効か？
        require( _arrPriceDirect[scoutType] <= msg.value, "insufficient value" );

        // 対象のスロットの特定
        uint256 target = 0;
        for( uint256 j=0; j<_arrCartridges[scoutType].length; j++ ){
            if( _arrCartridges[scoutType][j].checkTokenId( tokenId ) ){
                target = j;
                break;
            }
        }

        // 参照先の変換
        uint256 at = _arrCartridges[scoutType][target].convTokenId( tokenId );
        require( at < _arrCartridges[scoutType][target].getRemaining(), "nonexistent data" );

        // mint
        _mintIdol( scoutType, _arrCartridges[scoutType][target], at, msg.sender );
    }

    //------------------------------------------
    // [external/onlyOwner] NFTの確保(giveaway用)
    //------------------------------------------
    function reserveIdol( uint256 scoutType, uint256 tokenId ) external onlyOwner {
        require( scoutType >= 0 && scoutType < SCOUT_TYPE_MAX, "invalid scout type" );

        // 対象のスロットの特定
        uint256 target = 0;
        for( uint256 j=0; j<_arrCartridges[scoutType].length; j++ ){
            if( _arrCartridges[scoutType][j].checkTokenId( tokenId ) ){
                target = j;
                break;
            }
        }

        // 参照先の変換
        uint256 at = _arrCartridges[scoutType][target].convTokenId( tokenId );
        require( at < _arrCartridges[scoutType][target].getRemaining(), "nonexistent data" );

        // mint
        _mintIdol( scoutType, _arrCartridges[scoutType][target], at, msg.sender );
    }

    //--------------------------------------
    // [internal] mint実体
    //--------------------------------------
    function _mintIdol( uint256 scoutType, ICartridge cartridge, uint256 dataAt, address holder ) internal {
        // データの取得
        uint256 data = cartridge.getDataAt( dataAt );

        // rarity
        uint256 rarity = data & 0xff;
        require( rarity == scoutType, "invalid rarity" );

        // tokenId
        uint256 tokenId = (data & 0xffffffff00) >> 8;

        // 属性数の判定
        uint256 numAttribute = 0;
        uint256 mask = 0xff0000000000;
        uint256 shift = 40;
        for( uint256 i=0; i<ATTRIBUTE_DATA_MAX; i++ ){
            uint256 attributeAt = (data & mask) >> shift;
            if( attributeAt > 0 ){
                require( attributeAt <= ATTRIBUTES.length, "invalid attribute" );
                numAttribute++;
            }
            mask <<= 8;
            shift += 8;
        }

        // 属性配列の作成
        string[] memory attributes = new string[](numAttribute);
        numAttribute = 0;
        mask = 0xff0000000000;
        shift = 40;
        for( uint256 i=0; i<ATTRIBUTE_DATA_MAX; i++ ){
            uint256 attributeAt = (data & mask) >> shift;
            if( attributeAt > 0 ){
                attributes[numAttribute] = ATTRIBUTES[attributeAt-1];
                numAttribute++;
            }
            mask <<= 8;
            shift += 8;
        }

        // mint
        IManager iManager = IManager(_manager);
        iManager.mintIdol( tokenId, rarity, attributes, holder );
        _arrMinted[scoutType]++;

        // データの消費
        cartridge.wasteAt( dataAt );
    }

    //--------------------------------------------------------
    // [external] 残高の確認
    //--------------------------------------------------------
    function checkBalance() external view returns (uint256) {
        return( address(this).balance );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] 引き出し
    //--------------------------------------------------------
    function withdraw( uint256 amount ) external onlyOwner {
        require( amount <= address(this).balance, "insufficient balance" );

        address payable target = payable( msg.sender );
        target.transfer( amount );
    }

}