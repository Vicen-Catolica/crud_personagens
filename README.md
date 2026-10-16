## Estrutura do Banco no Cloud Firestore

```text
usuarios                      (coleção)
  └── {uid}                   (documento: o id é o UID do Auth -> email, criadoEm)
        ├── personagens       (subcoleção)
        │     └── {id}        -> nome, vida, forca
        ├── missoes           (subcoleção)
        │     └── {id}        -> titulo, concluidaEm
        └── inventario        (subcoleção)
              └── {id}        -> nome, quantidade
```

---

## O que foi implementado

### Parte 1: Mover os personagens para a subcoleção (`usuarios/{uid}/personagens`)
- **[`lib/models/personagem.dart`](lib/models/personagem.dart)**: Removido o campo redundante `userId`, pois o vínculo com o usuário agora é garantido pelo próprio caminho do documento no Firestore.
- **[`lib/services/personagem_service.dart`](lib/services/personagem_service.dart)**:
    - A referência `_colecao` passou a apontar para `firestore.collection('usuarios').doc(_uid).collection('personagens')`.
    - O método `listarPersonagens()` consulta diretamente `_colecao.snapshots()`, eliminando a necessidade do filtro `.where('userId', isEqualTo: _uid)`.

### Parte 2: Security Rules (`firestore.rules`)
- **[`firestore.rules`](firestore.rules)**:
    - Usa a recursão `match /usuarios/{userId}/{document=**}` para garantir que apenas o usuário autenticado cujo `request.auth.uid == userId` possa ler e escrever dentro da sua própria árvore de documentos (incluindo o documento de perfil e qualquer subcoleção atual ou futura, como `personagens`, `missoes` e `inventario`).
    - Bloqueia qualquer acesso de usuários não autenticados (`request.auth != null`).
      Valida `(!('vida' in request.resource.data) || request.resource.data.vida >= 0)` em operações de `create` e `update`, impedindo que personagens sejam criados ou atualizados com vida negativa.

### Parte 3: Nova funcionalidade — Missões (`usuarios/{uid}/missoes`)
- **[`lib/models/missao.dart`](lib/models/missao.dart)** e **[`lib/services/missao_service.dart`](lib/services/missao_service.dart)**:
    - Permite registrar missões concluídas (`titulo`, `concluidaEm`), listar em tempo real ordenadas pela data de conclusão e excluir missões em `usuarios/{uid}/missoes`.

### Desafios Bônus Implementados
1. **Documento de perfil em `usuarios/{uid}`**: No cadastro (`AuthService.cadastrar`), o app grava `email` e `criadoEm` no documento `usuarios/{uid}` e exibe essas informações em tempo real no cabeçalho da `HomeScreen`.
2. **Subcoleção `inventario` (`usuarios/{uid}/inventario`)**: Criados [`lib/models/item_inventario.dart`](lib/models/item_inventario.dart) e [`lib/services/inventario_service.dart`](lib/services/inventario_service.dart) e a aba **Inventário** na `HomeScreen`, comprovando que a regra recursiva `{document=**}` já protege novas subcoleções sem precisar alterar o `firestore.rules`.
3. **Validação de vida não-negativa nas Security Rules**: Regra `request.resource.data.vida >= 0` aplicada em `firestore.rules`.

---

## Respostas das Perguntas de Reflexão

1. **Qual a diferença prática entre filtrar dados com `.where('userId', isEqualTo: uid)` em uma coleção raiz e organizar os dados em subcoleções `usuarios/{uid}/...`?**
    - Qualquer consulta exige lembrar de incluir `.where('userId', isEqualTo: uid)`, e consultas com ordenação (`orderBy`) frequentemente exigem índices compostos (`userId` + campo ordenado).
    - Com subcoleções (`usuarios/{uid}/personagens`, `usuarios/{uid}/missoes`), o isolamento é estrutural (pelo caminho). As queries ficam mais simples (`collection('usuarios').doc(uid).collection('personagens').snapshots()`), não precisam de índices compostos com `userId`, e a organização visual no console do Firestore reflete exatamente a hierarquia de posse dos dados.

2. **Por que o uso da recursão `{document=**}` simplifica as Security Rules ao adicionar novas funcionalidades (como `missoes` e `inventario`)?**
    - Sem subcoleções, cada nova coleção raiz (`personagens`, `missoes`, `inventario`) exigiria um bloco `match /nomeColecao/{docId}` próprio verificando `resource.data.userId == request.auth.uid` e `request.resource.data.userId == request.auth.uid`.
    - Com `match /usuarios/{userId}/{document=**}`, a verificação `request.auth != null && request.auth.uid == userId` baseia-se no `{userId}` presente no caminho da URL do documento. Assim, qualquer subcoleção criada dentro de `usuarios/{userId}` herda automaticamente a mesma proteção sem precisar tocar nas regras.

3. **O que acontece se o aplicativo no cliente não filtrar os dados ou tentar acessar `usuarios/{uidDeOutroUsuario}/personagens`?**
    - Se o cliente tentar ler `usuarios/{uidA}/personagens` estando autenticado como `uidB` (ou sem login), a condição `request.auth.uid == userId` falha e o Firestore rejeita a operação imediatamente com `PERMISSION_DENIED`.

4. **Por que validações como impedir vida negativa (`request.resource.data.vida >= 0`) devem existir nas Security Rules e não apenas na interface do Flutter?**
    - Validações feitas apenas no código cliente (Flutter) podem ser contornadas caso alguém chame a API REST/SDK do Firebase diretamente usando seu token de autenticação. Colocar a validação `request.resource.data.vida >= 0` nas Security Rules garante a integridade dos dados diretamente no servidor do Firestore.

---
