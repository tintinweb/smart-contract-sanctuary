pragma solidity 0.4.18;



interface InternalNetworkInterface {


    function listPairForReserve(
        address reserve,
        address token,
        bool ethToToken,
        bool tokenToEth,
        bool add
    )
        external
        returns(bool);

}


contract Lister {
    InternalNetworkInterface constant NETWORK = InternalNetworkInterface(0x9ae49C0d7F8F9EF4B864e004FE86Ac8294E20950);
    address constant PRYCTO = address(0x21433Dec9Cb634A23c6A4BbcCe08c83f5aC2EC18);

    modifier onlyListers() {
        require(msg.sender == 0x7C8cfF2c659A3eE23869497a56129F3da92E8F38 ||
                msg.sender == 0xd0643BC0D0C879F175556509dbcEe9373379D5C3);
        _;
    }

    function list(address reserve, address token) internal {
        require(NETWORK.listPairForReserve(reserve,token,true,true,true));
    }
    
    function listPrycto1() onlyListers public {
        // OMG
        list(PRYCTO,0xd26114cd6EE289AccF82350c8d8487fedB8A0C07);
        // KNC
        list(PRYCTO,0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
        // BAT
        list(PRYCTO,0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        // ENG
        list(PRYCTO,0xf0Ee6b27b759C9893Ce4f094b49ad28fd15A23e4);
    }

    function listPrycto2() onlyListers public {
        // REQ
        list(PRYCTO,0x8f8221aFbB33998d8584A2B05749bA73c37a938a);
        // RCN
        list(PRYCTO,0xF970b8E36e23F7fC3FD752EeA86f8Be8D83375A6);
        // ADX
        list(PRYCTO,0x4470BB87d77b963A013DB939BE332f927f2b992e);
        // DAI
        list(PRYCTO,0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    }

    function listPrycto3() onlyListers public {
        // REQ
        list(PRYCTO,0x8f8221aFbB33998d8584A2B05749bA73c37a938a);
        // RCN
        list(PRYCTO,0xF970b8E36e23F7fC3FD752EeA86f8Be8D83375A6);
        // ADX
        list(PRYCTO,0x4470BB87d77b963A013DB939BE332f927f2b992e);
        // AST
        list(PRYCTO,0x27054b13b1B798B345b591a4d22e6562d47eA75a);
    }
    
    function listPrycto4() onlyListers public {
        // DAI
        list(PRYCTO,0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
        // IOST
        list(PRYCTO,0xFA1a856Cfa3409CFa145Fa4e20Eb270dF3EB21ab);
        // STORM
        list(PRYCTO,0xD0a4b8946Cb52f0661273bfbC6fD0E0C75Fc6433);
        // LEND
        list(PRYCTO,0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
    }    
    
    function listPrycto5() onlyListers public {
        // WINGS
        list(PRYCTO,0x667088b212ce3d06a1b553a7221E1fD19000d9aF);
        // MTL
        list(PRYCTO,0xF433089366899D83a9f26A773D59ec7eCF30355e);
        // WABI
        list(PRYCTO,0x286BDA1413a2Df81731D4930ce2F862a35A609fE);
        // OCN
        list(PRYCTO,0x4092678e4E78230F46A1534C0fbc8fA39780892B);
    }        
    
    function listPrycto6() onlyListers public {
        // PRO
        list(PRYCTO,0x226bb599a12C826476e3A771454697EA52E9E220);
        // SSP
        list(PRYCTO,0x624d520BAB2E4aD83935Fa503fB130614374E850);
    }            
    
    function listMOT() onlyListers public {
        list(0x6f50e41885fdc44dbdf7797df0393779a9c0a3a6,0x263c618480DBe35C300D8d5EcDA19bbB986AcaeD);
    }

    function listINF() onlyListers public {
        list(0x4d864b5b4f866f65f53cbaad32eb9574760865e6,0x00E150D741Eda1d49d341189CAE4c08a73a49C95);
    }

    function listBBO() onlyListers public {
        list(0x91be8fa21dc21cff073e07bae365669e154d6ee1,0x84F7c44B6Fed1080f647E354D552595be2Cc602F);
    }

    function listCOFI() onlyListers public {
        list(0xc935cad589bebd8673104073d5a5eccfe67fb7b1,0x3136eF851592aCf49CA4C825131E364170FA32b3);
    }

    function listMOC() onlyListers public {
        list(0x742e8bb8e6bde9cb2df5449f8de7510798727fb1,0x865ec58b06bF6305B886793AA20A2da31D034E68);
    }

    function listMAS() onlyListers public {
        list(0x56e37b6b79d4e895618b8bb287748702848ae8c0,0x23Ccc43365D9dD3882eab88F43d515208f832430);
    }

    function listDTH() onlyListers public {
        list(0x2631a5222522156dfafaa5ca8480223d6465782d,0x5adc961D6AC3f7062D2eA45FEFB8D8167d44b190);
    }

    function listTCC() onlyListers public {
        list(0xa9312cb86d1e532b7c21881ce03a1a9d52f6adb1,0x9389434852b94bbaD4c8AfEd5B7BDBc5Ff0c2275);
    }

}