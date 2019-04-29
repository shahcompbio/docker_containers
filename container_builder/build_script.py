import os
import errno
import warnings
import argparse
from git import Git, Repo
from subprocess import Popen, PIPE


class TagFormatError(Exception):
    """
    Exception for cases when tag is not formatted correctly
    """
    def __init__(self, message):
        message = "Tag {} is not formatted correctly." \
                  "The tags should start with container name" \
                  " followed by version and separated by :. " \
                  "Example: bwa-v0.0.1".format(message)
        # self.message = message

        super(TagFormatError, self).__init__(message)

class InvalidTag(Exception):
    """
    Exception for cases when tag doesnt pass validation
    """


def makedirs(directory):
    """
    make a dir if it doesnt exist
    :param directory: dir path
    :type directory: str
    """
    try:
        os.makedirs(directory)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise


def check_if_tag_valid(container_name, version):
    """
    :param container_name: name of container
    :type container_name: str
    :param version: version string
    :type version: ver
    """
    list_of_all_dirs = get_immediate_subdirectories(os.getcwd()+ "/scp")

    if container_name not in list_of_all_dirs:
        error_str = 'Could not find directory corresponding to' \
                      ' container {}. Please check the container ' \
                      'name in tag'.format(container_name)
        raise InvalidTag(error_str)

    if not version.startswith('v'):
        raise InvalidTag('versions should start with v')

    version = version.split(',')
    if len(version) > 3 and not version[-1].startswith('rc'):
        warnings.warn('please follow semantic versioning guidelines')


def get_immediate_subdirectories(dirpath):
    """
    :param dirpath: path to main dir
    :type dirpath: str
    :return: all subdirs
    :rtype: list of str
    """
    directories = []
    for filesystem_node in os.listdir(dirpath):
        if os.path.isdir(os.path.join(dirpath, filesystem_node)):
            directories.append(filesystem_node)

    return directories


def get_latest_tag():
    """
    :return: container and version for latest tag in repo
    :rtype: tuple of str
    """
    # Get the tags from the repository
    repo = Repo(os.getcwd())
    tags = sorted(repo.tags, key=lambda t: t.commit.committed_datetime)

    latest_tag = str(tags[-1])

    if not len(latest_tag.split('-')) == 2:
        raise TagFormatError(latest_tag)

    container_name, version = latest_tag.split('-')
    container_name = container_name.lower()

    return container_name, version


def run_cmd(cmd, output=None):
    """
    run command with subprocess,
    write stdout to output file if set
    :param cmd: command args
    :type cmd: list of str
    :param output: filepath for stdout
    :type output: str
    """
    stdout = None
    if output:
        stdout = open(output, "w")

    p = Popen(cmd, stdout=stdout, stderr=PIPE)

    cmdout, cmderr = p.communicate()

    retc = p.returncode

    if retc:
        raise Exception(
            "command failed. stderr:{}, stdout:{}".format(
                cmdout,
                cmderr))

    if output:
        stdout.close()


def log_into_azure_acr(registry_url):
    """
    :param registry_url: azure registry url
    :type registry_url: str
    """
    username = os.environ['CLIENT_ID']
    password = os.environ['SECRET_KEY']

    login_command = [
        "docker", "login", registry_url, "-u", username, "--password", password
    ]
    run_cmd(login_command)


def log_into_aws_acr(tempdir):
    """
    :param tempdir: dir path to store intermediate files
    :type tempdir: str
    :return: registry url
    :rtype: str
    """
    makedirs(tempdir)
    stdoutfile = os.path.join(tempdir, 'aws_login_output.txt')

    login_command = ['aws', 'ecr', 'get-login', '--no-include-email']
    run_cmd(login_command, output=stdoutfile)

    login_command = open(stdoutfile).readlines()
    assert len(login_command) == 1
    login_command = login_command[0].split()

    registry_url = login_command[-1]

    run_cmd(login_command)

    # docker doesnt like https in url
    registry_url = registry_url.replace('https://', '')

    return registry_url


def docker_build_and_push_container(
        container_name, registry_url, version, prefix
):
    """
    :param container_name: name of container to build
    :type container_name: str
    :param registry_url: url for registry to push to
    :type registry_url: str
    :param version: version string to tag container with
    :type version: str
    :param prefix: prefix to add to container name
    :type prefix: str
    """

    check_if_tag_valid(container_name, version)

    print 'building version {} of container {}'.format(version, container_name)

    currentdir = os.getcwd()

    os.chdir(container_name)

    command = ['docker', 'build', '-t', container_name, '.']
    run_cmd(command)

    container_url = '{}/{}/{}:{}'.format(registry_url, prefix, container_name, version)

    command = ["docker", "tag", container_name, container_url]
    run_cmd(command)

    command = ['docker', 'push', container_url]
    run_cmd(command)

    os.chdir(currentdir)


def main(args):
    container, new_version = get_latest_tag()

    container_name_prefix = args.container_name_prefix

    if args.push_to_azure:
        azure_registry_url = args.azure_registry_url
        log_into_azure_acr(azure_registry_url)
        docker_build_and_push_container(
            container, azure_registry_url,
            new_version, container_name_prefix
        )

    if args.push_to_aws:
        aws_registry = log_into_aws_acr(args.tempdir)
        docker_build_and_push_container(
            container, aws_registry, new_version, container_name_prefix
        )


def parse_args():
    """
    specify and parse args
    """
    parser = argparse.ArgumentParser(
        description='''build and push docker containers'''
    )

    parser.add_argument('--tempdir',
                        required=True,
                        help='''dir to store temp files''')

    parser.add_argument('--push_to_azure',
                        default=False,
                        action='store_true',
                        help='''push container to azure''')

    parser.add_argument('--push_to_aws',
                        default=False,
                        action='store_true',
                        help='''push container to aws''')

    parser.add_argument('--azure_registry_url',
                        default='shahlab.azurecr.io',
                        help='''azure container registry url''')

    parser.add_argument('--container_name_prefix',
                        default='scp',
                        help='''container prefix''')

    args = parser.parse_args()

    return args


if __name__ == "__main__":
        args = parse_args()

        main(args)
