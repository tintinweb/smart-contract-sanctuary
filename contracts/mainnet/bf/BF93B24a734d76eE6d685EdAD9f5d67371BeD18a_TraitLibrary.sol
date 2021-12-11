// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library.sol";

contract TraitLibrary is Ownable {
    using Library for uint16;

    struct Trait {
        string traitName;
        string traitType;
        string rects;
        uint32 price;
    }

    //addresses
    address _owner;

    //uint arrays
    uint32[][9] PRICES;

    //byte arrays
    bytes[9] TYPES;
    bytes[][9] NAMES;
    bytes[][9] RECTS;
    bytes COLORS;

    constructor() {
        _owner = msg.sender;

        // Declare initial values
        TYPES = [
                bytes("background"),
                bytes("body"),
                bytes("eye"),
                bytes("antler"),
                bytes("hat"),
                bytes("neck"),
                bytes("mouth"),
                bytes("nose"),
                bytes("accessory")
        ];

        PRICES[0] = [0];
        PRICES[1] = [0];
        PRICES[2] = [0];
        PRICES[3] = [0];
        PRICES[4] = [0];
        PRICES[5] = [0];
        PRICES[6] = [0];
        PRICES[7] = [0];
        PRICES[8] = [0];

        NAMES[0] = [
                bytes("")
        ];
            

        NAMES[1] = [
                bytes("")
        ];
            

        NAMES[2] = [
                bytes("")
        ];
            

        NAMES[3] = [
                bytes("")
        ];
            

        NAMES[4] = [
                bytes("")
        ];
            

        NAMES[5] = [
                bytes("")
        ];
            

        NAMES[6] = [
                bytes("")
        ];
            

        NAMES[7] = [
                bytes("")
        ];
            

        NAMES[8] = [
                bytes("")
        ];
            

        RECTS[0] = [
                bytes("")
        ];

        RECTS[1] = [
                bytes("")
        ];

        RECTS[2] = [
                bytes("")
        ];

        RECTS[3] = [
                bytes("")
        ];

        RECTS[4] = [
                bytes("")
        ];
            
        RECTS[5] = [
                bytes("")

        ];
            
        RECTS[6] = [
                bytes("")

        ];

        RECTS[7] = [
                bytes("")
        ];

        RECTS[8] = [
                bytes("")
        ];
    }

    /**
     * @dev Gets the rects a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getRects(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (bytes memory rects)
    {
        // return string(abi.encodePacked(RECTS[traitIndex][traitValue]));
        return RECTS[traitIndex][traitValue];
    }

    /**
     * @dev Gets a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getTraitInfo(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (string memory traitName, string memory traitType)
    {
        return (
            string(abi.encodePacked(NAMES[traitIndex][traitValue])),
            string(abi.encodePacked(TYPES[traitIndex]))
        );
    }

    /**
     * @dev Gets the price of a trait from storage
     * @param traitIndex The trait type index
     * @param traitValue The location within the array
     */

    function getPrice(uint256 traitIndex, uint256 traitValue)
        public
        view
        returns (uint32 price)
    {
        return PRICES[traitIndex][traitValue];
    }

    /**
     * @dev Adds entries to trait metadata
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraits(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            PRICES[_traitTypeIndex].push(traits[i].price);
            NAMES[_traitTypeIndex].push(bytes(abi.encodePacked(traits[i].traitName)));
            RECTS[_traitTypeIndex].push(bytes(abi.encodePacked(traits[i].rects)));
        }

        return;
    }

    /**
     * @dev Clear entries to trait metadata
     * @param _traitTypeIndex The trait type index
     */

    function clearTrait(uint256 _traitTypeIndex)
        public
        onlyOwner
    {
        PRICES[_traitTypeIndex] = [0];
        NAMES[_traitTypeIndex] = [bytes("")];
        RECTS[_traitTypeIndex] = [bytes("")];
        return;
    }


   /**
     * @dev Gets the color string
     */

    function getColors()
        public
        pure
        returns (string memory colors)
    {
        return ".c000{fill:#000000}.c001{fill:#000008}.c002{fill:#00000a}.c003{fill:#00000b}.c004{fill:#000101}.c005{fill:#000202}.c006{fill:#001efd}.c007{fill:#001eff}.c008{fill:#002259}.c009{fill:#005189}.c010{fill:#006bff}.c011{fill:#008544}.c012{fill:#00881d}.c013{fill:#00aa0c}.c014{fill:#00b09e}.c015{fill:#00b4ff}.c016{fill:#00c7f1}.c017{fill:#00eaff}.c018{fill:#010000}.c019{fill:#010001}.c020{fill:#010101}.c021{fill:#017db1}.c022{fill:#020100}.c023{fill:#020202}.c024{fill:#022d00}.c025{fill:#024d01}.c026{fill:#02b4da}.c027{fill:#030202}.c028{fill:#030303}.c029{fill:#035223}.c030{fill:#040303}.c031{fill:#040309}.c032{fill:#0456c7}.c033{fill:#050505}.c034{fill:#051429}.c035{fill:#051c3e}.c036{fill:#060405}.c037{fill:#060605}.c038{fill:#070404}.c039{fill:#070707}.c040{fill:#080500}.c041{fill:#080604}.c042{fill:#080808}.c043{fill:#0879df}.c044{fill:#0904eb}.c045{fill:#090500}.c046{fill:#09897b}.c047{fill:#09f200}.c048{fill:#0a0a0a}.c049{fill:#0a0e13}.c050{fill:#0ad200}.c051{fill:#0b0907}.c052{fill:#0b0a09}.c053{fill:#0b0b0b}.c054{fill:#0b7b08}.c055{fill:#0b87f7}.c056{fill:#0b8f08}.c057{fill:#0d031e}.c058{fill:#0d0c0d}.c059{fill:#0d0d0d}.c060{fill:#0e0603}.c061{fill:#0e09c5}.c062{fill:#0e0d0d}.c063{fill:#0e0e0e}.c064{fill:#0f0602}.c065{fill:#0f095e}.c066{fill:#0f09f9}.c067{fill:#100603}.c068{fill:#101010}.c069{fill:#104b01}.c070{fill:#106ae7}.c071{fill:#107a46}.c072{fill:#1098b8}.c073{fill:#110502}.c074{fill:#110968}.c075{fill:#121111}.c076{fill:#131313}.c077{fill:#141414}.c078{fill:#141515}.c079{fill:#146b00}.c080{fill:#150f2d}.c081{fill:#156103}.c082{fill:#161616}.c083{fill:#17f4dd}.c084{fill:#18120a}.c085{fill:#182257}.c086{fill:#18371e}.c087{fill:#1a0db0}.c088{fill:#1a0eac}.c089{fill:#1c31c9}.c090{fill:#1d0ed1}.c091{fill:#1e1300}.c092{fill:#1e1b1c}.c093{fill:#1e1d1c}.c094{fill:#1f170d}.c095{fill:#2110ec}.c096{fill:#212121}.c097{fill:#215a36}.c098{fill:#231e1e}.c099{fill:#232222}.c100{fill:#252627}.c101{fill:#25b5f8}.c102{fill:#262929}.c103{fill:#272321}.c104{fill:#27ec0d}.c105{fill:#281900}.c106{fill:#29050a}.c107{fill:#299b01}.c108{fill:#2b3635}.c109{fill:#2c2729}.c110{fill:#2c27f3}.c111{fill:#2c2a28}.c112{fill:#2d130c}.c113{fill:#2e2113}.c114{fill:#2e260d}.c115{fill:#2e47ff}.c116{fill:#2e6a4b}.c117{fill:#2e9e40}.c118{fill:#2f0041}.c119{fill:#313021}.c120{fill:#323333}.c121{fill:#332eec}.c122{fill:#333a02}.c123{fill:#349d92}.c124{fill:#353537}.c125{fill:#364643}.c126{fill:#372014}.c127{fill:#372501}.c128{fill:#3a4703}.c129{fill:#3c2402}.c130{fill:#3d1005}.c131{fill:#3d301d}.c132{fill:#3d320e}.c133{fill:#3e383a}.c134{fill:#3e3e3e}.c135{fill:#3f3fed}.c136{fill:#3f4c03}.c137{fill:#410000}.c138{fill:#412ce5}.c139{fill:#422de5}.c140{fill:#424244}.c141{fill:#425c5a}.c142{fill:#435303}.c143{fill:#436060}.c144{fill:#448f61}.c145{fill:#44d0e6}.c146{fill:#451a08}.c147{fill:#464b64}.c148{fill:#473f42}.c149{fill:#47ffee}.c150{fill:#482e20}.c151{fill:#484a4a}.c152{fill:#494334}.c153{fill:#4a443f}.c154{fill:#4a4aff}.c155{fill:#4b1e0b}.c156{fill:#4b4545}.c157{fill:#4b4643}.c158{fill:#4b4a05}.c159{fill:#4c4c4c}.c160{fill:#4c8020}.c161{fill:#4d3b4d}.c162{fill:#4d4c48}.c163{fill:#4d5466}.c164{fill:#4f3533}.c165{fill:#4f4f51}.c166{fill:#4f5049}.c167{fill:#503820}.c168{fill:#504c47}.c169{fill:#513222}.c170{fill:#516d63}.c171{fill:#518d3c}.c172{fill:#520169}.c173{fill:#534016}.c174{fill:#535254}.c175{fill:#535556}.c176{fill:#535e9c}.c177{fill:#54ccff}.c178{fill:#554c4f}.c179{fill:#55aa48}.c180{fill:#564c4e}.c181{fill:#580002}.c182{fill:#582f19}.c183{fill:#585341}.c184{fill:#585858}.c185{fill:#595a5a}.c186{fill:#5a3200}.c187{fill:#5a5a5b}.c188{fill:#5a5a5c}.c189{fill:#5a9346}.c190{fill:#5c311a}.c191{fill:#5c5115}.c192{fill:#5c5a5b}.c193{fill:#5c8e8c}.c194{fill:#5d1d0c}.c195{fill:#5e341f}.c196{fill:#5e3700}.c197{fill:#5e5e5e}.c198{fill:#5fa551}.c199{fill:#604b31}.c200{fill:#614327}.c201{fill:#615c3c}.c202{fill:#624c3f}.c203{fill:#625e40}.c204{fill:#626262}.c205{fill:#632b1c}.c206{fill:#63564a}.c207{fill:#63605c}.c208{fill:#654f21}.c209{fill:#6574a4}.c210{fill:#6593eb}.c211{fill:#676767}.c212{fill:#684a11}.c213{fill:#686868}.c214{fill:#69ac0f}.c215{fill:#69bf9c}.c216{fill:#6a0500}.c217{fill:#6b3d02}.c218{fill:#6ba6db}.c219{fill:#6c0104}.c220{fill:#6d6949}.c221{fill:#6da25a}.c222{fill:#6e3421}.c223{fill:#6e6d6d}.c224{fill:#6f0809}.c225{fill:#700b00}.c226{fill:#707070}.c227{fill:#70c4ce}.c228{fill:#716e70}.c229{fill:#725e15}.c230{fill:#727877}.c231{fill:#72daff}.c232{fill:#737373}.c233{fill:#73b95a}.c234{fill:#73cd46}.c235{fill:#74bf2d}.c236{fill:#757575}.c237{fill:#75daf2}.c238{fill:#774000}.c239{fill:#775e07}.c240{fill:#776d6d}.c241{fill:#787e91}.c242{fill:#7b6c48}.c243{fill:#7d0600}.c244{fill:#7e0310}.c245{fill:#7e4002}.c246{fill:#7f4121}.c247{fill:#7f5203}.c248{fill:#807f7f}.c249{fill:#816f6f}.c250{fill:#824903}.c251{fill:#82682f}.c252{fill:#830316}.c253{fill:#83eceb}.c254{fill:#840915}.c255{fill:#848484}.c256{fill:#848999}.c257{fill:#850500}.c258{fill:#850915}.c259{fill:#858585}.c260{fill:#85db67}.c261{fill:#868787}.c262{fill:#87b037}.c263{fill:#880198}.c264{fill:#8ae586}.c265{fill:#8b4b00}.c266{fill:#8c170c}.c267{fill:#8c898b}.c268{fill:#8cbb2f}.c269{fill:#8d0015}.c270{fill:#8e23f2}.c271{fill:#8e5345}.c272{fill:#8e5900}.c273{fill:#8e5c00}.c274{fill:#8e7a16}.c275{fill:#8f6948}.c276{fill:#915e3c}.c277{fill:#916302}.c278{fill:#919191}.c279{fill:#920505}.c280{fill:#929192}.c281{fill:#930900}.c282{fill:#94910c}.c283{fill:#952318}.c284{fill:#95d8f5}.c285{fill:#96a3b1}.c286{fill:#974c0e}.c287{fill:#977730}.c288{fill:#989898}.c289{fill:#99ceec}.c290{fill:#9b0413}.c291{fill:#9b0993}.c292{fill:#9b3e00}.c293{fill:#9b8301}.c294{fill:#9c5582}.c295{fill:#9c8a22}.c296{fill:#9d7b10}.c297{fill:#9d8664}.c298{fill:#9eaecd}.c299{fill:#9ecfbe}.c300{fill:#9f0206}.c301{fill:#9f4c85}.c302{fill:#9fdcf7}.c303{fill:#a0a0a2}.c304{fill:#a0e066}.c305{fill:#a163a0}.c306{fill:#a17a01}.c307{fill:#a25201}.c308{fill:#a26adc}.c309{fill:#a27f08}.c310{fill:#a29da0}.c311{fill:#a37909}.c312{fill:#a3a3a3}.c313{fill:#a50001}.c314{fill:#a50311}.c315{fill:#a50f10}.c316{fill:#a642b6}.c317{fill:#a67b0d}.c318{fill:#a6d5c5}.c319{fill:#a7a3a6}.c320{fill:#a8895d}.c321{fill:#a8b1a8}.c322{fill:#aa7d54}.c323{fill:#abaaa6}.c324{fill:#ae8f6b}.c325{fill:#af0101}.c326{fill:#af5803}.c327{fill:#af8719}.c328{fill:#afe3fa}.c329{fill:#b00101}.c330{fill:#b0acac}.c331{fill:#b0acaf}.c332{fill:#b1b1b1}.c333{fill:#b20000}.c334{fill:#b2272b}.c335{fill:#b3362a}.c336{fill:#b40909}.c337{fill:#b4b0aa}.c338{fill:#b51f17}.c339{fill:#b58f6d}.c340{fill:#b69012}.c341{fill:#b6b6b7}.c342{fill:#b6eaff}.c343{fill:#b709be}.c344{fill:#b7875c}.c345{fill:#b7905a}.c346{fill:#b8b9b9}.c347{fill:#b9263d}.c348{fill:#ba0010}.c349{fill:#ba9a04}.c350{fill:#bc1622}.c351{fill:#bc2e2e}.c352{fill:#bea101}.c353{fill:#c06c00}.c354{fill:#c0834d}.c355{fill:#c1bcbc}.c356{fill:#c20417}.c357{fill:#c29f01}.c358{fill:#c32a1c}.c359{fill:#c3762a}.c360{fill:#c3a812}.c361{fill:#c4b299}.c362{fill:#c504a9}.c363{fill:#c5c8c9}.c364{fill:#c80409}.c365{fill:#c900cb}.c366{fill:#cad0c9}.c367{fill:#cc3443}.c368{fill:#cccccc}.c369{fill:#ccced1}.c370{fill:#cd7079}.c371{fill:#cda601}.c372{fill:#cda65d}.c373{fill:#cdc3c3}.c374{fill:#cdcfd2}.c375{fill:#cdd0d2}.c376{fill:#cebd22}.c377{fill:#cfcfcf}.c378{fill:#cfd0d0}.c379{fill:#d08507}.c380{fill:#d095f5}.c381{fill:#d15b2b}.c382{fill:#d20000}.c383{fill:#d22121}.c384{fill:#d27935}.c385{fill:#d27dd4}.c386{fill:#d2b52a}.c387{fill:#d31017}.c388{fill:#d4a0f7}.c389{fill:#d4cd16}.c390{fill:#d59702}.c391{fill:#d5d5d5}.c392{fill:#d5ff84}.c393{fill:#d6b19f}.c394{fill:#d6d6d6}.c395{fill:#d70101}.c396{fill:#d7b2a0}.c397{fill:#d7b943}.c398{fill:#d8d85c}.c399{fill:#d8d8d8}.c400{fill:#d9b3fa}.c401{fill:#d9c6ab}.c402{fill:#db0d0d}.c403{fill:#db5c0f}.c404{fill:#dbb348}.c405{fill:#dbecf2}.c406{fill:#dd2a2a}.c407{fill:#dd3ea3}.c408{fill:#dd4638}.c409{fill:#dedede}.c410{fill:#dfba39}.c411{fill:#e08811}.c412{fill:#e1ebff}.c413{fill:#e25245}.c414{fill:#e26012}.c415{fill:#e27a04}.c416{fill:#e3c0b4}.c417{fill:#e3e3e3}.c418{fill:#e3edff}.c419{fill:#e3f1ff}.c420{fill:#e45526}.c421{fill:#e4c6bc}.c422{fill:#e4d954}.c423{fill:#e4effe}.c424{fill:#e504e7}.c425{fill:#e5b53b}.c426{fill:#e5c688}.c427{fill:#e5e5e5}.c428{fill:#e60e0e}.c429{fill:#e6de04}.c430{fill:#e812f5}.c431{fill:#e870d2}.c432{fill:#e92828}.c433{fill:#e936a8}.c434{fill:#e9392d}.c435{fill:#e9fadf}.c436{fill:#ea8700}.c437{fill:#eb362d}.c438{fill:#eba3ba}.c439{fill:#ebacc0}.c440{fill:#ebf4f7}.c441{fill:#ec2eab}.c442{fill:#ece401}.c443{fill:#ed6dd1}.c444{fill:#edd2b7}.c445{fill:#ee5c07}.c446{fill:#eec06e}.c447{fill:#eeca00}.c448{fill:#eeeeee}.c449{fill:#ef402c}.c450{fill:#efcb00}.c451{fill:#efeb89}.c452{fill:#efeded}.c453{fill:#f08306}.c454{fill:#f0d74d}.c455{fill:#f0e110}.c456{fill:#f19949}.c457{fill:#f1f1f1}.c458{fill:#f23289}.c459{fill:#f2584a}.c460{fill:#f2f0f0}.c461{fill:#f327ae}.c462{fill:#f33a84}.c463{fill:#f34080}.c464{fill:#f3c87b}.c465{fill:#f3f0f0}.c466{fill:#f4ab3a}.c467{fill:#f4f0f0}.c468{fill:#f4f1f1}.c469{fill:#f5596e}.c470{fill:#f5735d}.c471{fill:#f57859}.c472{fill:#f6f2f2}.c473{fill:#f7d81e}.c474{fill:#f7f4f4}.c475{fill:#f7f6f6}.c476{fill:#f8f6f6}.c477{fill:#f8f8f8}.c478{fill:#f90808}.c479{fill:#f9ce6b}.c480{fill:#f9dc3b}.c481{fill:#f9e784}.c482{fill:#f9ec76}.c483{fill:#fa1a02}.c484{fill:#faf569}.c485{fill:#faf6f6}.c486{fill:#fbdd4b}.c487{fill:#fbf6f6}.c488{fill:#fc0000}.c489{fill:#fc00ff}.c490{fill:#fcf301}.c491{fill:#fdde60}.c492{fill:#fde80c}.c493{fill:#fde85e}.c494{fill:#febc0e}.c495{fill:#fec02a}.c496{fill:#fec901}.c497{fill:#fee85d}.c498{fill:#feed84}.c499{fill:#fef601}.c500{fill:#ff0000}.c501{fill:#ff002a}.c502{fill:#ff00f6}.c503{fill:#ff2626}.c504{fill:#ff2a2f}.c505{fill:#ff7200}.c506{fill:#ff9000}.c507{fill:#ffb400}.c508{fill:#ffd627}.c509{fill:#ffd800}.c510{fill:#ffe646}.c511{fill:#fff201}.c512{fill:#fff383}.c513{fill:#fff600}.c514{fill:#ffffff}";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Library {

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
            result[i] = _stringBytes[i];
            if(i==_pos)
            result[i]=bytes(_letter)[0];
        }
        return  string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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