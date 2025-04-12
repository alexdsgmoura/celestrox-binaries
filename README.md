# Celestrox - Recursos Extras

Este binário foi desenvolvido para fornecer funcionalidades extras que complementam o funcionamento do Celestrox. Ele agrega recursos adicionais que aprimoram e expandem as capacidades do sistema principal.

## Arquivos Binários Disponíveis

Após a compilação, os seguintes binários serão gerados:

- **celestrox_amd64**  
  *Arquitetura:* x86_64 (64 bits)  
  *Uso:* Ideal para sistemas Linux modernos, tanto em servidores quanto em desktops com processadores de 64 bits.

- **celestrox_386**  
  *Arquitetura:* 32 bits (i386, i486, i586, i686)  
  *Uso:* Recomendado para sistemas Linux mais antigos ou com hardware que possua arquitetura de 32 bits.

- **celestrox_armv7**  
  *Arquitetura:* ARM (32 bits, ARMv7)  
  *Uso:* Indicado para dispositivos embarcados ou sistemas com processadores ARM de 32 bits.

- **celestrox_arm64**  
  *Arquitetura:* ARM de 64 bits (aarch64)  
  *Uso:* Utilizado em dispositivos modernos com processadores ARM de 64 bits, como alguns modelos de Raspberry Pi e outros sistemas integrados.

> **Observação:**  
> Todos os binários são compilados sem o uso de bibliotecas C (com `CGO_ENABLED=0`), garantindo que o projeto seja inteiramente construído em Go sem dependências externas de C.

## Como Utilizar

1. **Selecione o binário adequado para o seu sistema:**
   - Para sistemas Linux 64 bits: utilize `celestrox_amd64`.
   - Para sistemas Linux 32 bits: utilize `celestrox_386`.
   - Para dispositivos ARM de 32 bits: utilize `celestrox_armv7`.
   - Para dispositivos ARM de 64 bits: utilize `celestrox_arm64`.
