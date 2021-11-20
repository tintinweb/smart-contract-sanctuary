// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiSoullyTwoDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'Soully Yokai #2';
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
        return '<svg id="Soully Yokai" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="420" height="420" viewBox="0 0 420 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g> <g id="Body" > <g id="Yokai"> <path id="Neck" d="M175.8,276.8c.8,10,1.1,20.2-.7,30.4a9.31,9.31,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a11.17,11.17,0,0,1-5.1-8.3,125.18,125.18,0,0,1-.1-22.2,164.09,164.09,0,0,1,4.6-29.3" transform="translate(0.2 0.4)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.1,279s24.2,35,41,30.6S260.8,288,260.8,288c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a108.88,108.88,0,0,1-29.8,13.3Z" transform="translate(0.2 0.4)" fill="#7099ae" fill-rule="evenodd" style="isolation: isolate"/> <path id="Head" d="M313.9,168.8c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86C268.5,73.7,242.2,64,214.5,63.4c-24.5-.5-48.7,10.9-61.6,24.4-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.85,22.85,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.85,4.85,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8Z" transform="translate(0.2 0.4)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ear" d="M141.9,236c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7" transform="translate(0.2 0.4)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear"> <path d="M304.2,175.2a10.65,10.65,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a50.9,50.9,0,0,1,3.8-6.8,22.4,22.4,0,0,1,5.1-5.9,29.22,29.22,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z" transform="translate(0.2 0.4)"/> </g> <g id="Buste"> <path d="M222.2,339.7c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.6,339.7,226.9,339.8,222.2,339.7Z" transform="translate(0.2 0.4)" fill="#2b232b"/> <path d="M142.3,337.2c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C150.8,338,146.7,337.6,142.3,337.2Z" transform="translate(0.2 0.4)" fill="#2b232b"/> <path d="M199.3,329.2l1.6,3c.5,1,1,2,1.6,3a16.09,16.09,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.57,3.57,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a53.67,53.67,0,0,1-4.4,5.1,32.13,32.13,0,0,1-5.1,4.6,2.51,2.51,0,0,1-.7.4,2.37,2.37,0,0,1-1,.3,1.45,1.45,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A59,59,0,0,1,199.3,329.2Z" transform="translate(0.2 0.4)" fill="#2b232b"/> <path d="M199.3,329.2s3.5,9.3,5.3,10.1,11.6-10,11.6-10C209.9,330.9,204,331.1,199.3,329.2Z" transform="translate(0.2 0.4)" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> <g> <line x1="128.52" y1="179.27" x2="134.26" y2="186.66" fill="#bfd2d3"/> <path d="M128.32,178.87a11.15,11.15,0,0,1,5.74,7.39,11.2,11.2,0,0,1-5.74-7.39Z" transform="translate(0.2 0.4)"/> </g> </g> <g id="Nose"> <g id="Akuma"> <path d="M191.6,224.5c6.1,1,12.2,1.7,19.8.4l-8.9,6.8a1.5,1.5,0,0,1-1.8,0Z" transform="translate(0.2 0.4)" fill="#22608a" stroke="#22608a" stroke-miterlimit="10" opacity="0.5" style="isolation: isolate"/> <path d="M196.4,229.2c-.4.3-2.1-.9-4.1-2.5s-3-2.7-2.6-2.9,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2Z" transform="translate(0.2 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M206.5,228.7c.3.4,2.2-.3,4.2-1.7s3.5-2,3.2-2.4-2.5-.7-4.5.7C207.4,226.9,206.1,228.2,206.5,228.7Z" transform="translate(0.2 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> <g id="Eyes" > <g id="Pupils"> <g> <g id="No_Fill"> <g> <path d="M219.1,197.3s3.1-22.5,37.9-15.5C257.1,181.7,261,208.8,219.1,197.3Z" transform="translate(0.2 0.4)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M227.3,182.1a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3s-1.5,1.7-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6s.5-1,.8-1.6a17.2,17.2,0,0,1,4.7-5.1A4.88,4.88,0,0,1,227.3,182.1Z" transform="translate(0.2 0.4)" fill="#2f3555"/> <path d="M245.4,200.9a13.64,13.64,0,0,0,3.6-1,14.53,14.53,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5,34,34,0,0,0,2.3-3,7.65,7.65,0,0,1-1.7,3.5,10.65,10.65,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.4,200.9Z" transform="translate(0.2 0.4)" fill="#2f3555"/> </g> <g> <path d="M183.9,197.3s-3.1-22.5-37.9-15.5C146,181.7,142,208.8,183.9,197.3Z" transform="translate(0.2 0.4)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M175.8,182.1a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3s1.5,1.7,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6s-.5-1-.8-1.6a17.2,17.2,0,0,0-4.7-5.1A5.15,5.15,0,0,0,175.8,182.1Z" transform="translate(0.2 0.4)" fill="#2f3555"/> <path d="M157.6,200.9a13.64,13.64,0,0,1-3.6-1,14.53,14.53,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5,34,34,0,0,1-2.3-3,7.65,7.65,0,0,0,1.7,3.5,10.65,10.65,0,0,0,2.8,2.8,11.37,11.37,0,0,0,3.5,1.7A7.14,7.14,0,0,0,157.6,200.9Z" transform="translate(0.2 0.4)" fill="#2f3555"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.3,191.6s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C218.9,183.8,218.3,191.6,218.3,191.6Z" transform="translate(0.2 0.4)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow-2" opacity="0.43"> <path d="M184.9,191.3s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.4,183.6,184.9,191.3,184.9,191.3Z" transform="translate(0.2 0.4)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> </g> </g> <g id="Stitch_Eyes"> <g id="Strip"> <path d="M231.3,188.2s1-3.2,2.6-.9a30.48,30.48,0,0,1-.6,9.2s-.9,2-1.5-.5C231.3,193.3,232.3,193,231.3,188.2Z" transform="translate(0.2 0.4)" fill="#60d5dc" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M239.4,187.7s1-3.1,2.5-.9a28.56,28.56,0,0,1-.6,8.9s-.9,1.9-1.4-.5S240.5,192.4,239.4,187.7Z" transform="translate(0.2 0.4)" fill="#60d5dc" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M245.9,187.7s.9-2.7,2.2-.8a26.25,26.25,0,0,1-.5,7.7s-.8,1.7-1.1-.4S246.9,191.8,245.9,187.7Z" transform="translate(0.2 0.4)" fill="#60d5dc" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M251.4,187.4s.8-2.4,2-.7a21.16,21.16,0,0,1-.5,6.9s-.7,1.5-1-.4C251.4,191.2,252.1,191,251.4,187.4Z" transform="translate(0.2 0.4)" fill="#60d5dc" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> <g id="Strip"> <path d="M173.2,187.9s-1-3.1-2.5-.9a27.9,27.9,0,0,0,.6,8.8s.9,1.9,1.4-.5S172.2,192.5,173.2,187.9Z" transform="translate(0.2 0.4)" fill="#52d784" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M165.4,187.7s-1-3.1-2.5-.9a28.56,28.56,0,0,0,.6,8.9s.9,1.9,1.4-.5S164.4,192.4,165.4,187.7Z" transform="translate(0.2 0.4)" fill="#52d784" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M158.9,187.7s-.9-2.7-2.2-.8a26.25,26.25,0,0,0,.5,7.7s.8,1.7,1.1-.4C158.9,192,158.1,191.8,158.9,187.7Z" transform="translate(0.2 0.4)" fill="#52d784" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M153.4,187.4s-.8-2.4-2-.7a21.16,21.16,0,0,0,.5,6.9s.7,1.5,1-.4C153.4,191.2,152.6,191,153.4,187.4Z" transform="translate(0.2 0.4)" fill="#52d784" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> </g> <g id="Mouth"> <g id="Stitch"> <path d="M146.7,249c10.6,1.8,21.4,2.9,32.1,3.9,2.7.2,5.3.5,8,.7s5.4.3,8,.5c5.4.2,10.7.2,16.2.1s10.7-.5,16.2-.7l8-.6,4.1-.3,4-.4c10.7-1,21.3-2.9,31.9-4.8v.1l-7.9,1.9-4,.8c-1.4.3-2.6.5-4,.7l-8,1.4c-2.7.4-5.3.6-8,1-5.3.7-10.7.9-16.2,1.4-5.4.2-10.7.4-16.2.3-10.7-.1-21.6-.3-32.3-.9a261.6,261.6,0,0,1-31.9-5.1Z" transform="translate(0.2 0.4)"/> <path d="M192.9,254.2a39.12,39.12,0,0,1,17.5.2S201.6,257.3,192.9,254.2Z" transform="translate(0.2 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <g> <path d="M215.2,250.7s1.1-3.4,2.8-1a33.15,33.15,0,0,1-.7,9.9s-1,2.2-1.6-.6S216.3,255.9,215.2,250.7Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M223.3,250.9s1-3.1,2.5-.9a28.56,28.56,0,0,1-.6,8.9s-.9,1.9-1.4-.5C223.3,255.8,224.2,255.5,223.3,250.9Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M229.7,250.8s.9-2.7,2.2-.8a26.25,26.25,0,0,1-.5,7.7s-.8,1.7-1.1-.4C229.7,255,230.6,254.8,229.7,250.8Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M235.2,250.5s.8-2.4,2-.7a21.16,21.16,0,0,1-.5,6.9s-.7,1.5-1-.4S236,254.1,235.2,250.5Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> <g> <path d="M188.4,250.3s-1.1-3.4-2.8-1a33.15,33.15,0,0,0,.7,9.9s1,2.2,1.6-.6S187.1,255.5,188.4,250.3Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M180.4,250.5s-1-3.1-2.5-.9a28.56,28.56,0,0,0,.6,8.9s.9,1.9,1.4-.5S179.4,255,180.4,250.5Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M173.8,250.4s-.9-2.7-2.2-.8a26.25,26.25,0,0,0,.5,7.7s.8,1.7,1.1-.4S172.9,254.4,173.8,250.4Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M168.2,250s-.8-2.4-2-.7a21.16,21.16,0,0,0,.5,6.9s.7,1.5,1-.4C168.2,253.9,167.5,253.7,168.2,250Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> </g> <g id="Accessoire"> <g id="Eye"> <path d="M200.39,132.9s-15.61,16.62-1.08,39.88C199.41,172.69,214.75,155.06,200.39,132.9Z" transform="translate(0.2 0.4)" fill="#2f3555" fill-rule="evenodd"/> <path d="M207.33,139.57c3.28,8.88,3.32,19.39-1.68,27.57C209.46,158.53,209.4,148.72,207.33,139.57Z" transform="translate(0.2 0.4)" fill="#2f3555"/> <path d="M190.85,155c.66,5.62,1.52,11.24,4.5,16.21C191.75,166.8,190.81,160.47,190.85,155Z" transform="translate(0.2 0.4)" fill="#2f3555"/> <path d="M202.56,142.35c1-.27,1.94,6.35.94,6.33C202.39,149.05,201.46,142.43,202.56,142.35Z" transform="translate(0.2 0.4)" fill="#60d5dc" fill-rule="evenodd"/> </g> </g> <g id="Mask"> <g id="Stitch"> <path d="M175.8,299.3a201.42,201.42,0,0,0,21.7,3.9c1.9.2,3.5.5,5.4.7s3.6.3,5.4.5c3.6.2,7.2.2,10.9.1s7.2-.5,10.9-.7l5.4-.6c.9-.1,1.9-.2,2.7-.3l2.7-.4a179.87,179.87,0,0,0,21.5-4.8v.1l-5.5,1.9-2.7.8a26.81,26.81,0,0,1-2.7.7l-5.4,1.4c-1.9.4-3.5.6-5.4,1-3.5.7-7.2.9-10.9,1.4-3.6.2-7.2.4-10.9.3-7.2-.1-14.6-.3-21.8-.9-7-1.3-14.3-2.6-21.3-5.1Z" transform="translate(0.2 0.4)"/> <path d="M206.9,304.5a18.12,18.12,0,0,1,11.8.2A13.94,13.94,0,0,1,206.9,304.5Z" transform="translate(0.2 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <g> <path d="M222.1,301s.7-3.4,1.9-1a50.8,50.8,0,0,1-.5,9.9s-.7,2.2-1-.6S222.7,306.2,222.1,301Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M227.4,301.2s.7-3.1,1.7-.9a45.37,45.37,0,0,1-.4,8.9s-.6,1.9-.9-.5C227.4,306.1,228.2,305.8,227.4,301.2Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M231.8,301.1s.6-2.7,1.5-.8a37.85,37.85,0,0,1-.3,7.7s-.5,1.7-.7-.4C231.8,305.3,232.3,305.1,231.8,301.1Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M235.5,300.8s.5-2.4,1.4-.7a30.43,30.43,0,0,1-.3,6.9s-.5,1.5-.7-.4S236,304.4,235.5,300.8Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> <g> <path d="M203.8,300.5s-.7-3.4-1.9-1a50.8,50.8,0,0,0,.5,9.9s.7,2.2,1-.6S203.1,305.8,203.8,300.5Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M198.5,300.8s-.7-3.1-1.7-.9a45.37,45.37,0,0,0,.4,8.9s.6,1.9.9-.5S197.7,305.3,198.5,300.8Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M194.1,300.6s-.6-2.7-1.5-.8a37.85,37.85,0,0,0,.3,7.7s.5,1.7.7-.4S193.6,304.7,194.1,300.6Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M190.4,300.3s-.5-2.4-1.4-.7a30.43,30.43,0,0,0,.3,6.9s.5,1.5.7-.4C190.4,304.2,189.9,304,190.4,300.3Z" transform="translate(0.2 0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> </g> </svg>';
    }

    function generateDescription() private pure returns (string memory){
        return 'yokai\'chain x spiritswap';
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