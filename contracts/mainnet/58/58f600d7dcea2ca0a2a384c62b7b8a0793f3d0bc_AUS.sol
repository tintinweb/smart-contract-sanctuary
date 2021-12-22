// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [size=9px][font=monospace][color=#060703]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                              //
//    [color=#070803]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#070702]██████████████████████████████████████████████████████████████████████▓█████████[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#060503]█████████████████████████████████████████████████▌▓[/color][color=#3a403e]▓[/color][color=#3b403d]▓█[/color][color=#080e07]█[/color][color=#020502]█████████████████████████[/color]                                                                                                                                                                                            //
//    [color=#060503]██████████████████████████████████████████████████▓[/color][color=#373d3a]▓▓████████████[/color][color=#3b403d]▓███████[/color][color=#0e1205]███████[/color]                                                                                                                                                                                                                   //
//    [color=#070602]████████████████████████████████████████████████▓[/color][color=#383d3e]▓[/color][color=#373c3d]▓▓▓█[/color][color=#060b04]█[/color][color=#030702]████████▀[/color][color=#585b59]▒[/color][color=#46494b]▓▓[/color][color=#1a221c]█[/color][color=#0e150d]██████▓▓▓███[/color]                                                                                                //
//    [color=#070602]██████████████████████████████████▓███████████[/color][color=#424742]▓[/color][color=#535955]▀╜`` ╙'░░░░░░▒▒▒▒╣╫▓█[/color][color=#121811]█[/color][color=#1a1a0d]██████▓▓▓▓█[/color]                                                                                                                                                                                            //
//    [color=#070602]█████████████████████████████████▓██████████[/color][color=#635c4d]▒[/color][color=#776c5b]▒▒░     ¿▒▒▒▒@▒▒▒▒╢╢╢▓▓[/color][color=#20231d]█[/color][color=#1d1c0f]████████▓▓▓[/color]                                                                                                                                                                                            //
//    [color=#070602]████████████████████████████████████▓▓████▌[/color][color=#7c6742]╣[/color][color=#937440]▒╢▒░  .╓▒▒▒╣╫╣▒╢╢▓▓▓█▓▓▓▓█▓▓[/color][color=#392510]█[/color][color=#2f1c0a]███████[/color]                                                                                                                                                                                            //
//    [color=#060702]████████████████████████████████████▓[/color][color=#5b5746]▓[/color][color=#5e543c]▓[/color][color=#282512]█▓▄▒▓╣╢▒'  ░▒╣╢▓╢▄▄▓▒╣╢╢▓▓▒▓▓▓▓▓▓▀▓▓███[/color][color=#281c0c]██[/color]                                                                                                                                                                                            //
//    [color=#060602]███████████████████████████████████▓[/color][color=#514d43]▓[/color][color=#55504a]▒▒▒░░░░░░─[/color][color=#767876]░░▒▒╢▓█[/color][color=#231c15]█[/color][color=#1d1819]█[/color][color=#464b51]▀▓███▓▓▓▓▓▓▓█▓▓[/color][color=#4f4d48]▓▒╣▓▓▓▓▓█[/color]                                                                                                                       //
//    [color=#070602]█[/color][color=#070602]████████████████████████████████[/color][color=#3e3d38]▓[/color][color=#3c3b37]▓█▓▓██▓░[/color][color=#707271]▒  [/color][color=#717372]░▒▒▒╣▒▒╣[/color][color=#563927]▓╣╢▒▒[/color][color=#624c36]▓▓▓▓███▓█▓▓▓▓▓▓▒▒▒▓╣╣▓[/color]                                                                                                                       //
//    [color=#060602]█[/color][color=#060602]████████████████████████████████████████[/color][color=#3b3d3a]▌[/color][color=#68696a]░[/color][color=#727272]░░▒▒▒▒▒▒║▒▓▒▒╢╫▓[/color][color=#483720]▓[/color][color=#2d2211]█████▓▓▓██▓█▒[/color][color=#737371]░[/color][color=#60605e]▒▒▒▓[/color][color=#4a463c]▓▓[/color]                                                                         //
//    [color=#060702]█[/color][color=#060702]██████████████████████████████[/color][color=#5d5d57]▒████[/color][color=#3e3a34]▓▓▓▓▓▒░░░░▒▒╫▓▒▒▒▒▒╣▓▓[/color][color=#2e2618]███▓▓▓▓▓▓▓▓██▓▌[/color][color=#6e6e6c]▒[/color][color=#525250]▒▒▒▀[/color][color=#1d1c15]██[/color]                                                                                                                       //
//    [color=#060702]███████████████████████████████[/color][color=#6e706d]░[/color][color=#625f5b]║[/color][color=#403b36]▓[/color][color=#312921]██▓▓▓▒▒▒[/color][color=#6a6b6c]░[/color][color=#676969]▒▒▒▒▒╫▓[/color][color=#34322d]█▓▒░▒▒╢[/color][color=#503f29]▓███▓▓▓▓▓▓▓▓▓██▌Ñ[/color][color=#696967]▒▒▓▓▓█[/color]                                                                         //
//    [color=#060702]█[/color][color=#060702]██████████████████████████████[/color][color=#696b69]░[/color][color=#6e6a69]░╫▓[/color][color=#3d3733]▓[/color][color=#3b302c]▓▓▓▓╣[/color][color=#666768]▒[/color][color=#646667]▒▒▒╢╬▓▓▓[/color][color=#292620]█▓▒▒▒▒▓[/color][color=#543c20]▓▓▓▓▓▓▓▓▓▓▓▓█▓█[/color][color=#545451]╢[/color][color=#696865]▒╬╣║▓▓[/color][color=#191814]█[/color]    //
//    [color=#060702]███████████████████████████████[/color][color=#4f504c]▄[/color][color=#696764]▒╢▓▓▓▓▓▓║▒▒╣▓▓▓▓▓▓▓▓▓╣▒╟▓▓▓██▓▓▓▓▓▓▓▓▓▓[/color][color=#232014]█▒▓▒▒▓[/color][color=#34312c]▓██[/color]                                                                                                                                                                                            //
//    [color=#060702]█████████████████████████████████▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓███▓▓╣▓▓▒▓███[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#060702]███████████████████████████████████[/color][color=#4a4b46]▓[/color][color=#5e5e59]▒╢╢╣╫▓▓▓▓▓▓▓▓█▓[/color][color=#1e1912]█[/color][color=#1d1812]██▓[/color][color=#59584b]╣[/color][color=#5c5849]▓▓▓▓▓█▓▓▓█[/color][color=#462d0f]█[/color][color=#422d12]███▓[/color][color=#5c5a50]╣[/color][color=#5e5d58]╢╫▓█▓▓[/color][color=#1e1e19]█[/color][color=#141511]█[/color]    //
//    [color=#040502]█████████████████████████████████████[/color][color=#53534c]╣[/color][color=#666358]╜╩▓╢╢╣▓▓╢╣▓╢▓╣╢╢╣╢╢╣▓▓▓▓▓▓╜╜╜╜▒▒▒▒▒╫▓▓▓▓[/color][color=#1b1e1a]█[/color][color=#0f120f]█[/color]                                                                                                                                                                                            //
//    [color=#030301]███████████████████████████████████[/color][color=#414540]▓[/color][color=#61635f]▒░    ╠╢╢╢╣╣╣╢╢╢╣╬╣╣╢▓▓▓▓╣╜░    [/color][color=#787771]`░▒▒▒╫▓▓▒╢[/color][color=#1e211e]█[/color][color=#030502]█[/color]                                                                                                                                                                     //
//    [color=#030301]██████████████████████████████████[/color][color=#434843]▓[/color][color=#5e6260]▒▒░░[/color][color=#7a7b75]░  `▒▒▒╢╢╢╢╢╢╢╣▓▓▓▓▓▓╣╣       ░░░▒╢╫▓[/color][color=#2d312d]▓[/color][color=#161b17]███[/color]                                                                                                                                                                     //
//    [color=#030301]██████████████████████████████████[/color][color=#525451]╣[/color][color=#5f615e]▒▒░░░░  ░░▒▒▒╢╢╢╫▓▓▓▓▓▓▓▓╣▒░    ░░░░░▒▒╫█[/color][color=#050704]█[/color][color=#010301]███[/color]                                                                                                                                                                                            //
//    [color=#030301]█████████████████████████████████[/color][color=#434641]▓[/color][color=#565854]Ñ╫▒▒░░░░░░░░▒╢╢╢╢▓▓▓▓▓▓▓▒▒▒░░[/color][color=#757670]░░░░░▒▒▒▒▒╫▓[/color][color=#1c1e1d]█[/color][color=#050605]████[/color]                                                                                                                                                                     //
//    [color=#120e01]████████████████████████████████▓[/color][color=#474944]▓[/color][color=#53544e]╣▒▒▒░░░▒▒▒▒▒░░▒╢╢╢╣▒▒▒▒▒▒▒░░░░▒▒▒▒╣ÑÑ╣╣▓█[/color][color=#0d0e0d]█[/color][color=#020403]████[/color]                                                                                                                                                                                            //
//    [color=#040401]████████████████████████████████[/color][color=#343631]▓[/color][color=#4a4c47]▓▒▒▒[/color][color=#666762]▒░g╢╣▒▒▒░░▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒║╢▓▓▓▓▓▓█[/color][color=#191a17]█[/color][color=#141819]██████[/color]                                                                                                                                                                     //
//    [color=#020200]████████████████████████████████▓[/color][color=#545652]╣[/color][color=#333531]█[/color][color=#151813]█▓▓▓[/color][color=#656661]▒[/color][color=#6b6c67]░▒▒▒▒▒▒▒▒▒▒░░▒░▒▒▒▒▒▒▒╢▓╫╫▓▓[/color][color=#3f302c]▓[/color][color=#682c35]▓▓▓████████[/color]                                                                                                                       //
//    [color=#080802]█[/color][color=#090902]███████████████████████████████████[/color][color=#3f433f]▓[/color][color=#5a5d5a]▒░░[/color][color=#72736e]░░░▒▓▓▓m▒▒▒▒░▒▒▒▒▒▒▒╬▓▒▒▒▒▓▓▀╢╫▓▓▓▓▓[/color][color=#272c2b]▓[/color][color=#262d2e]███[/color]                                                                                                                                              //
//    [color=#040500]██████████████████████████████████▀▒[/color][color=#626461]▒[/color][color=#6c6d6a]░░░░░░▐▓▓╜  ░  ░░░▒▒▒▒▒▒▒▒░░░░▒░▒░▒▒▒▒╣▓▓[/color][color=#252c2d]▓[/color][color=#1b2124]█[/color]                                                                                                                                                                                            //
//    [color=#020401]████████████████████████████████▓▓[/color][color=#525451]╣[/color][color=#5b5c5a]▒▒░░░░░▒░░░░,░░░░░░░░░░▒░░░░░  ░░░░▒░▒▒▒▒╣▒▒█[/color]                                                                                                                                                                                                                                          //
//    [color=#090b06]█[/color][color=#090b06]███████████████████████████████▓[/color][color=#474a47]▓[/color][color=#545651]╣▒▒░░░░░░░░░░░░░░░░░░░░░ ░░ ░ ░░░░░░░▒▒▒▒▒▒╫▓▓[/color]                                                                                                                                                                                                                   //
//    [color=#0a0b06]█[/color][color=#0b0c07]███████████████████████████████[/color][color=#3c403f]▓[/color][color=#4f5352]╢▒▒▒░░░░▒░░[/color][color=#72716c]░░░░░░░           ░ ░░░░░░▒▒▒▒▒▓▓▓▓▓[/color]                                                                                                                                                                                            //
//    [color=#0c0d08]█[/color][color=#0b0c07]███████████████████████████████[/color][color=#444847]▓[/color][color=#515554]╣▒▒░░░░░░░░░░░░░░░             ░░░░░▒▒▒▒╢╬▓▓▓▓█[/color]                                                                                                                                                                                                                   //
//    [color=#0c0d08]█[/color][color=#0c0d08]██████████████████████████████[/color][color=#393e3a]▓[/color][color=#505350]▒▒▒▒░[/color][color=#6e6e69]░░░░░░░░░░░░░ ░         ░░░░░░░░▒▒▒▒▒╬╣▓▓▓[/color][color=#1e1f21]█[/color]                                                                                                                                                                     //
//    [color=#0e0d09]██████████████████████████████▓[/color][color=#53544f]╣[/color][color=#5a5b56]▒▒▒▒▒▒▒░░░░░░░░░░░ ░          ░░░░░░░▒▒▒▒▒▒╬▓▓▓[/color][color=#191d20]█[/color]                                                                                                                                                                                                                   //
//    [color=#100f0b]██████████████████████████████▓[/color][color=#51524d]╣[/color][color=#595a54]╣▒▒▒▒▒▒▒░░░░░░░░░ ░░            ░░░░░▒▒▒▒▒▒╢╬▓▓▓[/color]                                                                                                                                                                                                                                          //
//    [color=#10100b]█[/color][color=#0f0f0a]█████████████████████████████▓[/color][color=#4c4e49]╣[/color][color=#555651]╣▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░            '░░░▒▒▒▒▒▒▒╢╣╫▓▓[/color]                                                                                                                                                                                                                   //
//    [color=#12120c]█[/color][color=#10100b]█████████████████████████████▓[/color][color=#4b4c47]╣[/color][color=#545550]╣╣▒▒▒▒▒▒▒▒▒▒▒░░░░░░░           ░░░░░▒▒╣▒▒▒▒╢╢▓▓▓[/color]                                                                                                                                                                                                                   //
//    [color=#12110c]█[/color][color=#14130e]█████████████████████████████▓[/color][color=#4e4f4a]╣[/color][color=#555650]╢╣▒▒▒▒▒▒▒▒▒▒▒▒░░░░░            ░░░░░▒▒▒╢╢╢╢╢▓▓▓▓[/color]                                                                                                                                                                                                                   //
//    [color=#12100c]█[/color][color=#15130e]████████████████████████████▓[/color][color=#464741]▓[/color][color=#4f504a]╢╣╣▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░[/color][color=#787772]░      ░ ░░░░░░▒▒▒▒╢╣╣▓▓▓▓█[/color]                                                                                                                                                                                            //
//    [color=#14110c]█[/color][color=#17140f]████████████████████████████▓[/color][color=#474741]▓[/color][color=#4f5049]╣╣╣▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░    [/color][color=#767673]░░░░░░▒▒▒▒▒╢╫╣▓▓▓▓▓[/color][color=#101419]█[/color]                                                                                                                                                                     //
//    [color=#15120d]████████████████████████████▓▓[/color][color=#4e4e46]╣[/color][color=#53534b]╢╣╣╢▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░, ░░░░░░░▒▒▒▒╫╢▓▓▓▓▓▓█[/color][color=#060809]█[/color]                                                                                                                                                                                                                   //
//    [color=#191611]████████████████████████████[/color][color=#3e3e3b]▓[/color][color=#4b4a43]▓╣╣╢╢╣╣╣▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒░[/color][color=#6f706b]░▒░░░░░░░▒▒▒╢╣╣▓▓▓▓▓██[/color][color=#030504]█[/color]                                                                                                                                                                                            //
//    [color=#181812]███████████████████████████[/color][color=#3f403a]▓[/color][color=#4d4a43]╣╣╢╢╣╣╢╢╢╣╣▒▒▒▒▒▒▒▒░░░░░░░▒▒▒░[/color][color=#6e6f6b]░░░░░▒▒▒▒╫╣╢╫▓▓▓▓▓▓▓█[/color][color=#030303]█[/color]                                                                                                                                                                                            //
//    [color=#1a1812]██████████████████████████[/color][color=#42433b]▓[/color][color=#4d4b44]▓╣╣╢╣╢╢╢╢╢▓▓▓╣▒▒╢▒▒▒░░░░░░░░▒▒░░[/color][color=#6f6f6d]░░░▒▒▒╢╢▓▓▓▓▓▓▓▓█▓▓█[/color][color=#0a0a0b]█[/color]                                                                                                                                                                                            //
//    [color=#191611]████████████████████████▓[/color][color=#464640]▓[/color][color=#544f46]╢▓╣╣╢╣╢╣╢╢▓██▓╣╣╣▒╢▒▒▒▒▒▒░░░░░░░░░░░░▒╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]                                                                                                                                                                                                                                          //
//    [color=#1e1b13]█[/color][color=#1d1a12]██████████████████████▓╣[/color][color=#565246]╣[/color][color=#534e43]▓▓╣╣╢╢╢╢▓▓▓▓╣╬╢▓▓╢▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]                                                                                                                                                                                                                   //
//    [color=#1d1a14]█[/color][color=#1c1813]████████████████████▓▓[/color][color=#4f4e45]╢[/color][color=#575246]╢▓▓▓╢╣╣╢▓▓██▓▓▓▓[/color][color=#1c1a11]█[/color][color=#14120b]██▓[/color][color=#4b4a44]▓[/color][color=#605f59]▒▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▓▓▓▓▓▓▓▓▓▓╣▓▓█▓[/color]                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AUS is ERC721Creator {
    constructor() ERC721Creator("Merle", "AUS") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}