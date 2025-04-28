# Развёртывание виртуального маршрутизатора - Mikrotik Cloud Hosted Router (CHR) в Yandex Cloud


С помощью данного решения можно развернуть виртуальный маршрутизатор [Mikrotik Cloud Hosted Router (CHR)](https://help.mikrotik.com/docs/spaces/ROS/pages/18350234/Cloud+Hosted+Router+CHR) в [Yandex Cloud](https://yandex.cloud).

Процесс развёртывания `CHR` в [Yandex Cloud](https://yandex.cloud) состоит из 2х этапов:
1. Подготовка [образа диска](https://yandex.cloud/docs/compute/concepts/image) для развертывания ВМ. При подготовке образа для развертывания используется оригинальное ПО из раздела `Cloud Hosted Router` на сайте [Mikrotik](https://mikrotik.com/download).
2. Создание [виртуальной машины](https://yandex.cloud/docs/compute/concepts/vm) (ВМ) из подготовленного в п.1 образа диска.


## Порядок развёртывания <a id="deploy"/></a>

Для выполнения развёртывания необходимо использовать операционную систему Linux или MacOS. 

Развёртывание в среде [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/) не гарантируется!

1. Убедиться, что все необходимые инструменты для развёртывания установлены и настроены:
* `git` - [установлен](https://git-scm.com/downloads) и [настроен](https://git-scm.com/book).
* `curl` - [установлен](https://curl.se/download.html).
* `yc CLI` - [установлен](https://yandex.cloud/docs/cli/operations/install-cli) и [настроен](https://yandex.cloud/docs/cli/).
* `Terraform` - [установлен](https://yandex.cloud/docs/tutorials/infrastructure-management/terraform-quickstart#install-terraform) и [настроен](https://yandex.cloud/docs/tutorials/infrastructure-management/terraform-quickstart#configure-provider).

2. Загрузить решение из репозитория на [github.com](https://github.com/yandex-cloud-examples/yc-deploy-mikrotik-chr):
    ```bash
    git clone https://github.com/yandex-cloud-examples/yc-deploy-mikrotik-chr.git
    ```

3. Перейти в папку с развёртыванием.
    ```bash
    cd yc-deploy-mikrotik-chr
    ```

4. Выбрать [на сайте Mikrotik](https://mikrotik.com/download) в разделе `Cloud Hosted Router` нужную версию для развёртывания.

5. Подготовить окружение для выполнения развёртывания.
    ```bash
    source ./env-yc.sh
    ```

6. Запустить сборку [образа диска](https://yandex.cloud/docs/compute/concepts/image) для выбранной версии CHR. При запуске сборки необходимо указать: 
    * выбранную `версию CHR`
    * идентификатор [облачного каталога](https://yandex.cloud/docs/resource-manager/concepts/resources-hierarchy#folder) в котором образ будет создаваться.

    ```bash
    ./chr-build-image.sh 7.18.2 b1g28**********yvxc3
    ```

    После успешной сборки, в указанном облачном каталоге будет создан образ диска с именем вида `mikrotik-chr-<version>`, а на экран показаны идентификаторы каталога и созданного в нём образа диска.
    ```
    ...
    chr_image_folder_id = "b1g28**********yvxc3"
    chr_image_id = "fd8to**********1ejrf"
    ```

7. Заполнить параметры развёртывания ВМ с CHR в файле [terraform.tfvars](./terraform.tfvars).

    Ниже приведен список параметров с примерами их заполнения. Подробнее со всеми параметрами развёртывания можно ознакомиться в файле [variables.tf](./variables.tf).

    * `zone_id` - идентификатор [зоны доступности](https://yandex.cloud/docs/overview/concepts/geo-scope) в которой будет развёртываться ВМ, например, `ru-central1-d`.

    * `vpc_subnet_id` - идентификатор [подсети](https://yandex.cloud/docs/vpc/concepts/network#subnet), куда будет подключаться создаваемая ВМ, например, `fl83k**********jbvnt`.

    * `chr_ip` - IP-адрес из подсети `vpc_subnet_id` для сетевого интерфейса ВМ, например, `10.150.0.150`.

    * `allowed_ip_list` - список доверенных IPv4-адресов от которых будут разрешаться соединения к CHR ВМ. Например, `["10.120.1.0/24", "10.150.0.0/24"]`. Поддерживаются только `IPv4` адреса. Ограничение доступа обеспечивается механизмом [групп безопасности](https://yandex.cloud/docs/vpc/concepts/security-groups), который будет настроен на сетевом интерфейсе ВМ. В список доверенных IP-адресов автоматически будет добавлен публичный IP-адрес с которого будет выполняться развёртывание (seed_ip). 

    * `chr_name` - имя для виртуального маршрутизатора CHR, например, `yc-chr`.

    * `admin_name` - имя для администратора ВМ, например, `oper`. Учётная запись администратора по-умолчанию `admin` будет удалена в процессе развёртывания.

    * `admin_key_file` - путь к файлу с публичным SSH ключём для учётной записи администратора, например, `~/.ssh/id_ed25519.pub`.

    * Параметры образа диска, полученные на предыдущем шаге. Могут быть скопированы из вывода процесса сборки образа диска (п.6), например:
        ```
        chr_image_folder_id = "b1g28**********yvxc3"
        chr_image_id = "fd8to**********1ejrf"
        ```

        Если ВМ разворачивается в том же облачном каталоге, где ранее был создан образ, то значение идентификатора каталога можно не указывать (оставить пустым).

8. Проверить и скорректировать (при необходимости) конфигурацию CHR в файле [chr-init.tpl](./chr-init.tpl).

9. Запустить развёртывание CHR с помощью инструмента Terraform.
    ```bash
    terraform apply
    ```

    Ожидаемый результат:
    ```
    connection-string = "ssh oper@<public-ip-address>"
    ```

10. Подключиться к CHR по протоколу SSH с помощью `connection-string` из предыдущего шага.

    ```bash
    ssh oper@<public-ip-address>
    ```

    После подключения к CHR нажать в терминале `n` или пробел для отказа от просмотра лицензионного соглашения.

    Ожидаемый результат:
    ```
    [oper@yc-chr] > 
    ```

## Удаление развёртывания и освобождение ресурсов <a id="destroy"/></a>

1. Перейти в каталог с развёртыванием.
    ```bash
    cd yc-deploy-mikrotik-chr
    ```

2. Подготовить окружение для удаления развёртывания.
    ```bash
    source ./env-yc.sh
    ```

3. Удалить развёртывание CHR ВМ с помощью инструмента `Terraform`.

    ```bash
    terraform destroy
    ```

4. Удалить образ диска для CHR ВМ с помощью инструмента `YC CLI`.

    ```bash
    yc compute image delete --id fd8to**********1ejrf --folder-id b1g28**********yvxc3
    ```
