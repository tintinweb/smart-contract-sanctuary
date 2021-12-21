// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiWAGMIDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'WAGMI Yokai #1';
        string memory description = generateDescription();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() private pure returns (string memory){
        return '<svg id="Akuma Edition" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="419.9" height="420" viewBox="0 0 419.9 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g><g id="Body" > <g id="Blood_Yokai" data-name="Blood Yokai"> <path id="Neck" d="M175.8,276.8c.8,10,1.1,20.2-.7,30.4a9.31,9.31,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a11.17,11.17,0,0,1-5.1-8.3,125.18,125.18,0,0,1-.1-22.2,164.09,164.09,0,0,1,4.6-29.3" transform="translate(-0.5 0.4)" fill="#e31466" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.1,279s24.2,35,41,30.6S260.8,288,260.8,288c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a108.88,108.88,0,0,1-29.8,13.3Z" transform="translate(-0.5 0.4)" fill-rule="evenodd" opacity="0.21" style="isolation: isolate"/> <path id="Head" d="M313.9,168.8c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86C268.5,73.7,242.2,64,214.5,63.4c-24.5-.5-48.7,10.9-61.6,24.4-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.85,22.85,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.85,4.85,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8Z" transform="translate(-0.5 0.4)" fill="#e31466" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ear" d="M141.9,236c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7" transform="translate(-0.5 0.4)" fill="#e31466" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear2"> <path d="M304.2,175.2a10.65,10.65,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a50.9,50.9,0,0,1,3.8-6.8,22.4,22.4,0,0,1,5.1-5.9,29.22,29.22,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z" transform="translate(-0.5 0.4)"/> </g> <g id="Buste"> <path d="M222.2,339.7c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.6,339.7,226.9,339.8,222.2,339.7Z" transform="translate(-0.5 0.4)" fill="#2b232b"/> <path d="M142.3,337.2c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C150.8,338,146.7,337.6,142.3,337.2Z" transform="translate(-0.5 0.4)" fill="#2b232b"/> <path d="M199.3,329.2l1.6,3c.5,1,1,2,1.6,3a16.09,16.09,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.57,3.57,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a53.67,53.67,0,0,1-4.4,5.1,32.13,32.13,0,0,1-5.1,4.6,2.51,2.51,0,0,1-.7.4,2.37,2.37,0,0,1-1,.3,1.45,1.45,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A59,59,0,0,1,199.3,329.2Z" transform="translate(-0.5 0.4)" fill="#2b232b"/> <path d="M199.3,329.2s3.5,9.3,5.3,10.1,11.6-10,11.6-10C209.9,330.9,204,331.1,199.3,329.2Z" transform="translate(-0.5 0.4)" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> <g> <line x1="127.8" y1="179.3" x2="133.6" y2="186.7" fill="none"/> <path d="M128.3,178.9a11,11,0,0,1,5.7,7.4,11.84,11.84,0,0,1-5.7-7.4Z" transform="translate(-0.5 0.4)"/> </g> </g> <g id="Marks"> <path id="Moon_White" data-name="Moon White" d="M218.2,146.2a17.4,17.4,0,0,0-7.2-14.7,12.73,12.73,0,0,1,3.6,9.4,13.86,13.86,0,1,1-23.6-10,17.57,17.57,0,0,0,9.2,32.3A17.45,17.45,0,0,0,218.2,146.2Z" transform="translate(-0.5 0.4)" fill="#ffeded"/> <g id="Blood_Akuma" data-name="Blood Akuma"> <g id="Eye_Mark" data-name="Eye Mark"> <path d="M237.6,224c0-3.6,2.6-85.2,2.8-88.9s-1.8-24.7-1.6-28.3c5.6-6.5,11.4-32.8,15.3-33-4.5,2.4-7.7,29.2-10.9,33l-.2,31.1c.1,4.7-2.5,81.1-2.2,86.2a17.68,17.68,0,0,0-1.6,2.2A23.4,23.4,0,0,0,237.6,224Z" transform="translate(-0.5 0.4)" fill="#fff"/> </g> <g id="Eye_Mark-2" data-name="Eye Mark"> <path d="M163.3,223.4c-.1-3.6.1-88.4.2-92s1.8-21.8,2-25.4c5.5-6.6,13.9-34.7,18.4-34.6-5.3,2-11.8,33-14.9,37L166.2,134c.2,3.6,0,85.7.3,89.3l-1.7,3.1Z" transform="translate(-0.5 0.4)" fill="#fff"/> </g> </g> </g> <g id="Nose"> <g id="Akuma_Nose" data-name="Akuma Nose"> <path d="M191.6,224.5c6.1,1,12.2,1.7,19.8.4l-8.9,6.8a1.5,1.5,0,0,1-1.8,0Z" transform="translate(-0.5 0.4)" stroke="#000" stroke-miterlimit="10" opacity="0.35" style="isolation: isolate"/> <path d="M196.4,229.2c-.4.3-2.1-.9-4.1-2.5s-3-2.7-2.6-2.9,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2Z" transform="translate(-0.5 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M206.5,228.7c.3.4,2.2-.3,4.2-1.7s3.5-2,3.2-2.4-2.5-.7-4.5.7C207.4,226.9,206.1,228.2,206.5,228.7Z" transform="translate(-0.5 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> <g id="Eyes" > <g id="Akuma_Eye"> <g> <g id="No_Fill"> <g> <path d="M219.1,197.3s3.1-22.5,37.9-15.5C257.1,181.7,261,208.8,219.1,197.3Z" transform="translate(-0.5 0.4)" stroke="#000" stroke-miterlimit="10"/> <path d="M227.3,182.1a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3s-1.5,1.7-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6s.5-1,.8-1.6a17.2,17.2,0,0,1,4.7-5.1A4.88,4.88,0,0,1,227.3,182.1Z" transform="translate(-0.5 0.4)"/> <path d="M245.4,200.9a13.64,13.64,0,0,0,3.6-1,14.53,14.53,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5,34,34,0,0,0,2.3-3,7.65,7.65,0,0,1-1.7,3.5,10.65,10.65,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.4,200.9Z" transform="translate(-0.5 0.4)"/> </g> <g> <path d="M183.9,197.3s-3.1-22.5-37.9-15.5C146,181.7,142,208.8,183.9,197.3Z" transform="translate(-0.5 0.4)" stroke="#000" stroke-miterlimit="10"/> <path d="M175.8,182.1a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3s1.5,1.7,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6s-.5-1-.8-1.6a17.2,17.2,0,0,0-4.7-5.1A5.15,5.15,0,0,0,175.8,182.1Z" transform="translate(-0.5 0.4)"/> <path d="M157.6,200.9a13.64,13.64,0,0,1-3.6-1,14.53,14.53,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5,34,34,0,0,1-2.3-3,7.65,7.65,0,0,0,1.7,3.5,10.65,10.65,0,0,0,2.8,2.8,11.37,11.37,0,0,0,3.5,1.7A7.14,7.14,0,0,0,157.6,200.9Z" transform="translate(-0.5 0.4)"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.3,191.6s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C218.9,183.8,218.3,191.6,218.3,191.6Z" transform="translate(-0.5 0.4)" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow-2" opacity="0.43"> <path d="M184.9,191.3s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.4,183.6,184.9,191.3,184.9,191.3Z" transform="translate(-0.5 0.4)" opacity="0.5" style="isolation: isolate"/> </g> </g> <path d="M246.5,192h-13a1.26,1.26,0,0,1-1.3-1.3h0a1.26,1.26,0,0,1,1.3-1.3h13a1.26,1.26,0,0,1,1.3,1.3h0A1.49,1.49,0,0,1,246.5,192Z" transform="translate(-0.5 0.4)" fill="#fff"/> <path d="M169.9,192h-13a1.26,1.26,0,0,1-1.3-1.3h0a1.26,1.26,0,0,1,1.3-1.3h13a1.26,1.26,0,0,1,1.3,1.3h0A1.59,1.59,0,0,1,169.9,192Z" transform="translate(-0.5 0.4)" fill="#fff"/> </g> </g> <g id="Mouth_17" > <g id="Akuma_Mouth" > <path d="M279.4,242.9c-8.1,1.5-19.5,4.4-27.7,5.7a183.37,183.37,0,0,1-24.6,2.8l.3-.2-5.6,10.9-.4.7-.4-.7-5.3-10.4.4.2c-4.8.3-9.6.6-14.4.5a116.32,116.32,0,0,1-14.4-1.1l.4-.2L182,262.4l-.3.5-.3-.5-5.9-11.6.2.1-7.6-.6a66.26,66.26,0,0,1-7.6-1.1c-1.3-.2-2.5-.5-3.8-.8s-2.5-.6-3.8-1c-2.4-.7-4.9-1.5-7.3-2.4v-.1c2.5.4,5,1,7.5,1.6,1.3.2,2.5.5,3.8.8l3.8.8c2.5.5,5,1.1,7.5,1.6a38.44,38.44,0,0,0,7.6.8h.1l.1.1,6.1,11.6h-.5l5.5-11.3.1-.2h.3a137.42,137.42,0,0,0,14.3,1c4.8,0,9.6-.2,14.4-.5h.3l.1.2,5.3,10.4h-.7l5.7-10.8.1-.2h.2a183.41,183.41,0,0,0,24.5-2.6c8-1.1,18.9-3.2,27-4.5Z" transform="translate(-0.5 0.4)"/> </g> </g> <g id="Accessoire_16" > <g id="Small_Horn_White"> <g> <g> <path d="M275.73,326.75s10.09-3.34,12.89-16.46c0,0,8.75,8.69,1.26,25.61C283.85,334.56,278.93,331.5,275.73,326.75Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M276.51,327a13.62,13.62,0,0,0,13.12,8.38" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#ffdaea" stroke-miterlimit="10" fill-rule="evenodd"/> </g> <g> <path d="M298.49,338.09s9.84-4,11.77-17.27c0,0,9.31,8.08,2.95,25.46C307.1,345.35,302,342.62,298.49,338.09Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M299.28,338.25a13.63,13.63,0,0,0,13.64,7.49" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#ffdaea" stroke-miterlimit="10" fill-rule="evenodd"/> </g> </g> <g> <g> <path d="M150.18,325.84s-9.51-4.73-10.42-18.11c0,0-9.9,7.35-4.88,25.16C141,332.43,146.35,330.09,150.18,325.84Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M149.38,325.94a13.63,13.63,0,0,1-14.17,6.44" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#ffdaea" stroke-miterlimit="10" fill-rule="evenodd"/> </g> <g> <path d="M126.05,333.85s-9.18-5.35-9.21-18.77c0,0-10.36,6.69-6.52,24.79C116.49,339.81,121.94,337.83,126.05,333.85Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M125.25,333.89a13.65,13.65,0,0,1-14.57,5.49" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#ffdaea" stroke-miterlimit="10" fill-rule="evenodd"/> </g> </g> </g> <g id="Horn_White"> <g> <path d="M255.6,94.5s36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C267.8,114.5,259.6,105.9,255.6,94.5Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M256.7,94.8c-.1.2,4.3,18.1,22.8,24.4" transform="translate(-0.5 0.4)" fill="none" stroke="#ffdaea" stroke-miterlimit="10" stroke-width="2"/> </g> <g> <path d="M162.5,94s-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C150.3,114.1,158.5,105.4,162.5,94Z" transform="translate(-0.5 0.4)" fill="#ffdaea" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M161.7,94.1c.1.2-5.1,19-22.9,24.5" transform="translate(-0.5 0.4)" fill="none" stroke="#ffdaea" stroke-miterlimit="10" stroke-width="2"/> </g> </g> </g> </svg>';
    }

    function generateDescription() private pure returns (string memory){
        return 'yokai\'chain x WAGMI';
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title Describes Yokai via URI
interface IYokaiHeroesDescriptor {
    /// @notice Produces the URI describing a particular Yokai (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI() external view returns (string memory);
}