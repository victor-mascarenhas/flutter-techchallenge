Link para a gravação: https://drive.google.com/file/d/1zSLz63gNwWiY5XuuvQqOI5V6zuFEvKYd/view?usp=sharing

## Tecnologias Utilizadas

- **Flutter**
- **Firebase Authentication** para gerenciamento de usuários
- **Firebase Firestore** para armazenamento de transações
- **Firebase Storage** para upload e armazenamento de arquivos
- **Provider** para gerenciamento de estado
- **Intl** para formatação de datas e valores
- **File Picker** para seleção de arquivos
- **Flutter PDFView** e **Photo View** para visualização de documentos

## Funcionalidades

- **Autenticação de Usuários:** Cadastro, login e logout com Firebase Authentication.
- **Gerenciamento de Transações:** Criação e edição de transações.
- **Upload de Arquivos:** Anexar documentos às transações.
- **Visualização de Arquivos:** Visualizar imagens e PDFs associados às transações.
- **Filtragem de Transações:** Pesquisa por título, data e tipo (depósito ou transferência).
- **Paginação:** Carregamento dinâmico das transações conforme o usuário rola a tela.

## Instalação e Configuração

1. Clone este repositório:
   ```sh
   git clone https://github.com/seu-usuario/TechChallenge.git
   cd TechChallenge
   ```

2. Instale as dependências:
   ```sh
   flutter pub get
   ```

3. Configure o Firebase:

   * O arquivo com as configurações já está no projeto. Para configurar novamente:
   
   - Crie um projeto no Firebase.
   - Ative Authentication (Email/Password), Firestore Database e Storage.
   - Baixe o `google-services.json` e coloque na pasta `android/app`.
   - Crie os índices `type` Crescente, `userId` Crescente, `date` Decrescente e `__name__` Decrescente no Firestore

4. Atualize as Regras de Storage
   
    ```sh
    rules_version = '2';
    service firebase.storage {   
      match /b/{bucket}/o {
      match /user_files/{userId}/{allPaths=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
    ```
    
5. Atualize as Regras do Firestore
   
    ```sh
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if request.auth != null;
        }
      }
    }
    ```

6. Execute o aplicativo:
   ```sh
   flutter run
   ```

