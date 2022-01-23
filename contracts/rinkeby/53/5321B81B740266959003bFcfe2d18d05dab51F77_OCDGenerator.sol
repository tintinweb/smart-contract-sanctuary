//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library OCDGenerator {
    
    struct OCDRands {

       uint bg;
       uint flap;
       uint side;
       uint hole;
       uint eyecover;
       uint brws;
       uint top;

    }

    struct OCDColors {
       
       uint eyec;
       uint brwsc;
       uint outerc;
       uint shirtc;
       uint pktc;

    }
  
    function getBox(uint flap, uint side) public pure returns(string memory){
        
        string[4] memory flaps = [
            '<polygon class="c4" points="135 160 185 120 365 120 315 160 135 160"/> <line class="c5" x1="340" y1="140" x2="160" y2="140" stroke-width="7px"/> <polygon class="c12" points="179 145 308.5 145 321 135 191.5 135 179 145"/>',
            '<polygon class="c6" points="135 160 185 120 365 120 315 160 135 160"/><polygon class="c3" points="275 160 325 120 365 120 315 160 275 160"/><polygon class="c3" points="135 160 185 120 225 120 175 160 135 160"/><polygon class="c4" points="135 160 315 160 340 140 160 140 135 160"/><polygon class="c3" points="185 120 160 90 340 90 365 120 185 120"/>',
            '<polygon class="c3" points="185 120 160 60 340 60 365 120 185 120"/><polygon class="c3" points="275 155 325 115 365 120 315 160 275 155"/><polygon class="c4" points="135 160 315 160 330 100 150 100 135 160"/>',
            '<polygon class="c6" points="135 160 185 120 365 120 315 160 135 160"/><polygon class="c4" points="135 160 185 120 135 100 85 140 135 160"/><polygon class="c4" points="185 120 220 80 400 80 365 120 185 120"/><polygon class="c4" points="365 145 415 105 365 120 315 160 365 145"/><polygon class="c3" points="135 160 315 160 280 140 100 140 135 160"/>'            
        ];
        string[8] memory sides = [
            '',
            '<polyline class="c7" points="347.92 165.38 347.92 177.01 357.22 157.95 347.92 153.75 347.92 165.38"/><polygon class="c7" points="347.95 171.32 347.95 159.33 329.22 174.26 329.22 186.25 347.95 171.32" />',
            '<polyline class="c7" points="333.52 294.62 333.52 282.99 324.22 302.05 333.52 306.25 333.52 294.62"/><polygon class="c7" points="333.49 288.68 333.49 300.67 352.22 285.74 352.22 273.75 333.49 288.68" />',
            '<polygon class="c7" points="344.47 258.94 351.97 253 351.97 279.72 344.47 285.66 344.47 258.94"/><polyline class="c7" points="348.22 282.44 340.72 288.37 348.22 301 355.72 276.5 348.22 282.44" />',
            '<polygon class="c7" points="335.97 201.09 328.47 207 328.47 180.42 335.97 174.51 335.97 201.09"/><polyline class="c7" points="332.22 177.47 339.72 171.56 332.22 159 324.72 183.37 332.22 177.47" />',
            '<line class="c8" x1="325" y1="165" x2="325" y2="185" /><line class="c8" x1="330" y1="161" x2="330" y2="181" /><line class="c8" x1="335" y1="157" x2="335" y2="177" />',
            '<polygon class="c9" points="335.14 157 335.14 177 325.22 185.16 325.22 164.93 335.14 157"/> <polygon class="c10" points="333.37 161.07 333.37 175.76 327.07 180.93 327.07 166.09 333.37 161.07" />',
            '<path d="M348.81,159.82c0-3.27-.93-5.93-2.09-5.93a.94.94,0,0,0-.53.2h0l-13.44,10.35-.11.09h0c-.84.77-1.45,3-1.45,5.64,0,3.27.93,5.93,2.09,5.93a.85.85,0,0,0,.51-.19h0l13.44-10.36h0C348.14,164.92,348.81,162.6,348.81,159.82Z" />'
        ];

        string memory box =
            string(
                abi.encodePacked(
                    '<rect class="c2" x="135" y="160" width="180" height="180"/>',
                    '<polygon class="c3" points="365 300 315 340 315 160 365 120 365 300"/>',
                    flaps[flap],
                    sides[side]
                )
            );
        return box;
    }

    function getBrws(uint b) public pure returns(string memory){
        
        string memory lb = '<line x1="260" y1="204" x2="290" y2="204" stroke-width="10px"/>';
        string memory rb = '<line  x1="160" y1="204" x2="190" y2="204" stroke-width="10px"/>';

        if (b==0){
           lb='';
           rb='';
        }else if (b == 1){
            lb='<line x1="260" y1="184" x2="290" y2="184" stroke-width="10px"/>';
        }else if (b == 2){
            rb='<line  x1="160" y1="184" x2="190" y2="184" stroke-width="10px"/>';
        }else if (b == 3){
            lb='<line x1="260" y1="184" x2="290" y2="184" stroke-width="10px"/>';
            rb='<line  x1="160" y1="184" x2="190" y2="184" stroke-width="10px"/>';
        }
        string memory brws = string(
            abi.encodePacked(
                lb,
                rb
                 )
            );
       return brws;
    }
    
    function getCover(uint h, uint e ) public pure returns(string memory){

        string[4] memory cover_c =[
            '',
            '<path d="M150,240a25,25,0,0,1,50,0" /><path d="M250,240a25,25,0,0,1,50,0"/>',
            '<path d="M150,240a25,25,0,0,0,50,0" /><path d="M250,240a25,25,0,0,0,50,0"/>',
            '<rect x="275" y="225" width="15" height="30"/><rect x="175" y="225" width="15" height="30"/>'
        ];
        string[4] memory cover_r =[
            '',
            '<rect x="150" y="215" width="150" height="25"/>',
            '<rect x="150" y="240" width="150" height="25"/>',
            '<rect x="275" y="225" width="15" height="30"/><rect x="175" y="225" width="15" height="30"/>'
        ];
        string[2]memory light = [
            '<path d="M300,240a24.88,24.88,0,0,0-5-15h0a25,25,0,0,0-20,40h0A25,25,0,0,0,300,240Z" /><path d="M200,240a24.88,24.88,0,0,0-5-15h0a25,25,0,0,0-20,40h0A25,25,0,0,0,200,240Z"/>',
            '<rect class="cls-2" x="175" y="233" width="125" height="32.5"/>'
        ];
        
        string memory cover = string(
                abi.encodePacked(
                    h == 0 ? cover_c[e] : cover_r[e],
                    '<g fill="#fff" opacity="0.15">',
                    light[h],
                    '</g>'
                )
            );
        
        return cover;
    }

    function getPkt(uint t) public pure returns(string memory){
        
          string memory pkt;
        if(t == 0 || t == 3){
            pkt = '';
        }else if(t == 1 || t == 4){
            pkt ='<line x1="290" y1="420" x2="330" y2="420" stroke-width="10px"/>';
        }else if(t == 2){
            pkt = '<rect class="nf" x="290" y="417.5" width="40" height="25" rx="6.23"/><line class="r10" x1="290" y1="420" x2="330" y2="420"/>';
        }else if(t == 5){
            pkt = '<line class="s5" x1="290" y1="390" x2="290" y2="480" stroke-width="5px"/><line class="s5" x1="210" y1="390" x2="210" y2="480" stroke-width="5px"/>';
        }else if(t == 6){
            pkt = '<circle cx="210" cy="410" r="5"/><circle cx="210" cy="470" r="5"/>';
        }
        
        return pkt;
    }
    function randomOCD(string memory seed) public pure returns (OCDRands memory) {   
        OCDRands memory ocd;

        ocd.bg = random(seed, "bgcolor") % 15;
        ocd.flap = random(seed, "flip") % 4;
        ocd.side = random(seed, "side") % 7;
        ocd.hole =  random(seed, "hole") % 2;  // 0: circly 1: rect
        ocd.eyecover = random(seed, "eyecover") % 4;
        ocd.brws = random(seed, "brws") % 5;
        ocd.top = random(seed, "top") % 7;
        return ocd;
    }
    
    function getOCDForSeed(string memory seed) public pure returns (string memory)
    {
        OCDRands memory ocd = randomOCD(seed);
        OCDColors memory ocdc;
        
        //bg color
        ocdc.eyec = random(seed, "eyecolor") % 15;
        ocdc.brwsc = random(seed, "brwc") % 15;
        ocdc.shirtc = random(seed, "shirtc") % 15;
        ocdc.outerc = random(seed, "outerc") % 15;
        ocdc.pktc = random(seed, "pktc") % 13;

        string[15] memory colors = [           
                "2d2d2d","13294d","3a486c","9565cc","2f3087","544fcf","e54470","eaeaea","f2cf83","695150","2f98a5","2557ba","0f4856","df90e7","c750d0"
        ];
        string[13] memory colors1 = [           
                "143043","133e59","6ea2a4","3b8790","c9c3c9","ea8a46","e66e48","473ea6","4763a4","e26bb9","111","f03449","f0daaf"
        ];
        
        string memory bg =
            string(
                abi.encodePacked(
                    '<rect x="0" y="0" width="500" height="500" fill="#',
                    colors[ocd.bg],
                    '"></rect>'
                )
            );
        string memory box = getBox(ocd.flap, ocd.side);

        string[2] memory holes = [
            '<circle cx="175" cy="240" r="25" /><circle cx="275" cy="240" r="25"/>',
            '<rect x="150" y="215" width="150" height="50"/>'
        ];

        string memory eyes = string(
                abi.encodePacked('<g fill="#',
                colors[ocdc.eyec],
                '">',
                '<circle cx="175" cy="240" r="15"/><circle cx="275" cy="240" r="15"/>',
                "</g>"
                 )
            );
 
        string memory brws = string(
                abi.encodePacked('<g stroke="#',
                colors[ocdc.brwsc],
                '">',
                getBrws(ocd.brws),
                '</g>'
                 )
            );
        
        string memory face = string(
            abi.encodePacked(holes[ocd.hole],
            eyes,
            brws,
            getCover(ocd.hole, ocd.eyecover)
            )
        );

    
        string memory shirt = string(
            abi.encodePacked('<g fill="#',
            colors[ocdc.shirtc],
            '">',
            '<polyline class="s10" points="150 500 150 370 350 370 350 500"/>',
            '</g>'
            )
        );

        string memory outer = string(
            abi.encodePacked('<g fill="#',
            colors[ocdc.outerc],
            '">',
            '<polyline class="s10" points="150 500 150 370 230 370 230 500"/><polyline class="s10" points="270 500 270 370 350 370 350 500"/>'
            '</g>'
            '<rect class="c10" x="235" y="375" width="10" height="125" opacity="0.35"/>'
            )
        );
        string memory pocket = (ocd.top == 0 || ocd.top == 3 ) ? '' : (ocd.top == 2 || ocd.top == 5) ? getPkt(ocd.top) : (ocd.top == 1 || ocd.top == 4 ) ?
            string(abi.encodePacked(
                '<g stroke="#', 
                colors1[ocdc.pktc],
                '">',
                getPkt(ocd.top),
                '</g>' 
            )) : string(abi.encodePacked(
                '<g fill="#', 
                colors1[ocdc.pktc],
                '">',
                getPkt(ocd.top),
                '</g>' 
            ));

        string memory body = string(
            abi.encodePacked(
                shirt,
                (ocd.top<3) ? '' : outer,
                pocket
            )
        );
                
        // Build the SVG from various parts
        string memory svg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" presevAspectRatio="xMidYMid meet"><style>',
                '.s10{stroke:#262626; stroke-width:10px; stroke-linejoin:round;}',
                '.s5{stroke:#eaeaea; stroke-width:5px; stroke-linejoin:round;}',
                '.r10{stroke:#d60000; stroke-width:10px; stroke-linejoin:round;}',
                '.nf{fill:#eaeaea;}',
                '.c2{fill:#9b7f64; stroke:#262626; stroke-width:10px; stroke-linecap:round; stroke-linejoin:round;}',
                '.c3{fill:#5e4838; stroke:#262626; stroke-width:10px; stroke-linecap:round; stroke-linejoin:round;}',
                '.c4{fill:#ad927b; stroke:#262626; stroke-width:10px; stroke-linecap:round; stroke-linejoin:round;}',
                '.c5{fill:#5e4838; stroke:#262626; stroke-width:7px; stroke-linecap:round; stroke-linejoin:round;}',
                '.c6{stroke:#262626; stroke-width:10px; stroke-linecap:round; stroke-linejoin:round;}',
                '.c7{fill:#5b2424;}',
                '.c8{stroke:#5b2424;}',
                '.c9{stroke:#262626;stroke-width: 1px; fill:none;}',
                '.c10{fill:#262626;}',
                '.c12{fill:#c1ab9d;}',
                '</style>'
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                bg,
                box,
                face,
                body,
               '</svg>'
            )
        );

        return svg;
    }

    function random(string memory seed, string memory key) internal pure returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(key, seed)));
    }
}