/**
 *Submitted for verification at Etherscan.io on 2020-05-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.16 <0.7.0;


// SmartContract for Fractal Company - All Rights Reserved

//       :::::::::: :::::::::      :::      ::::::::  :::::::::::     :::     :::        
//       :+:        :+:    :+:   :+: :+:   :+:    :+:     :+:       :+: :+:   :+:        
//       +:+        +:+    +:+  +:+   +:+  +:+            +:+      +:+   +:+  +:+        
//       :#::+::#   +#++:++#:  +#++:++#++: +#+            +#+     +#++:++#++: +#+        
//       +#+        +#+    +#+ +#+     +#+ +#+            +#+     +#+     +#+ +#+        
//       #+#        #+#    #+# #+#     #+# #+#    #+#     #+#     #+#     #+# #+#        
//       ###        ###    ### ###     ###  ########      ###     ###     ### ########## 


contract Fractal {
    
    struct Inversor {
        address inversor;
        uint Dia_de_la_inversion;
        uint Inversion_en_ETH;
        bool Esta_Activo;
    }
    
    // Fractal Founds Wallet (ETH) by default
    address owner = 0x78c25AA14b12fa53efDB77a5a46A59e0c571d0A6;
    address payable FRACTALFOUNDS = 0x78c25AA14b12fa53efDB77a5a46A59e0c571d0A6; //by default
    
    // (1st)
    function Invertir_Ahora() public payable {
        
        require(msg.value > 0);
        uint investment = msg.value;
        
        Buscar_Inversor[msg.sender] = Inversor({
            inversor: msg.sender,
            Dia_de_la_inversion: block.timestamp,
            Inversion_en_ETH: investment,
            Esta_Activo: true
        });
        FRACTALFOUNDS.transfer(msg.value);
    }
    
    // (2nd)
    mapping (address => Inversor) public Buscar_Inversor;
    
    // (3rd)
    function Realizar_Pago(address payable _client) public payable {

        require(msg.value > 0);
        _client.transfer(msg.value);
        Buscar_Inversor[_client].Esta_Activo = false;
    }
    
    // (4th)
    function Cambiar_Direccion_de_Fractal_Founds (address payable _direccion) public {
        require (msg.sender == owner);
        FRACTALFOUNDS = _direccion;
    }
}